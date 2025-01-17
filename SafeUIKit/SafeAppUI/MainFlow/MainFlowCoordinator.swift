//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit
import MultisigWalletApplication
import IdentityAccessApplication
import Common
import UserNotifications

open class MainFlowCoordinator: FlowCoordinator {

    private let manageTokensFlowCoordinator = ManageTokensFlowCoordinator()
    let masterPasswordFlowCoordinator = MasterPasswordFlowCoordinator()
    let sendFlowCoordinator = SendFlowCoordinator()
    let newSafeFlowCoordinator = CreateSafeFlowCoordinator()
    let recoverSafeFlowCoordinator = RecoverSafeFlowCoordinator()
    let incomingTransactionsManager = IncomingTransactionsManager()
    private (set) var walletConnectFlowCoordinator: WalletConnectFlowCoordinator!
    /// Used for modal transitioning of Terms screen
    private lazy var overlayAnimatorFactory = OverlayAnimatorFactory()

    public var crashlytics: CrashlyticsProtocol?

    private var lockedViewController: UIViewController!

    private let transactionSubmissionHandler = TransactionSubmissionHandler()

    private var applicationRootViewController: UIViewController? {
        get { return UIApplication.shared.keyWindow?.rootViewController }
        set { UIApplication.shared.keyWindow?.rootViewController = newValue }
    }

    public init() {
        super.init(rootViewController: CustomNavigationController())
        configureGloabalAppearance()
        newSafeFlowCoordinator.mainFlowCoordinator = self
        recoverSafeFlowCoordinator.mainFlowCoordinator = self
    }

    private func configureGloabalAppearance() {
        UIButton.appearance().tintColor = ColorName.hold.color
        UIButton.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = nil

        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.barTintColor = ColorName.snowwhite.color
        navBarAppearance.tintColor = ColorName.hold.color
        navBarAppearance.isTranslucent = false
        navBarAppearance.setBackgroundImage(UIImage(), for: .default)
        navBarAppearance.shadowImage = Asset.shadow.image
    }

    // Entry point to the app
    open override func setUp() {
        super.setUp()
        appDidFinishLaunching()
    }

    func appDidFinishLaunching() {
        updateUserIdentifier()
        defer {
            ApplicationServiceRegistry.walletConnectService.subscribeForIncomingTransactions(self)
        }
        if !ApplicationServiceRegistry.authenticationService.isUserRegistered {
            push(OnboardingWelcomeViewController.create(delegate: self))
            applicationRootViewController = rootViewController
            return
        } else if ApplicationServiceRegistry.walletService.isSafeCreationInProgress {
            didSelectNewSafe()
        } else if ApplicationServiceRegistry.recoveryService.isRecoveryInProgress() {
            didSelectRecoverSafe()
        } else {
            switchToRootController()
        }
        requestToUnlockApp()
    }

    private func updateUserIdentifier() {
        guard let crashlytics = crashlytics,
            let wallet = ApplicationServiceRegistry.walletService.selectedWalletAddress else { return }
        crashlytics.setUserIdentifier(wallet)
    }

    func switchToRootController() {
        let nextController: UIViewController
        if ApplicationServiceRegistry.walletService.hasReadyToUseWallet {
            updateUserIdentifier()
            DispatchQueue.main.async(execute: registerForRemoteNotifciations)
            let mainVC = MainViewController.create(delegate: self)
            mainVC.navigationItem.backBarButtonItem = .backButton()
            nextController = mainVC
        } else {
            nextController = OnboardingCreateOrRestoreViewController.create(delegate: self)
        }
        navigationController.setViewControllers([nextController], animated: false)
    }


    func requestToUnlockApp(useUIApplicationRoot: Bool = false) {
        lockedViewController = useUIApplicationRoot ? applicationRootViewController : rootViewController
        applicationRootViewController = UnlockViewController.create { [unowned self] success in
            if !success { return }
            self.applicationRootViewController = self.lockedViewController
        }
    }

    open func appEntersForeground() {
        if ApplicationServiceRegistry.authenticationService.isUserRegistered &&
            !ApplicationServiceRegistry.authenticationService.isUserAuthenticated &&
            !(applicationRootViewController is UnlockViewController) {
            requestToUnlockApp(useUIApplicationRoot: true)
        }
    }

    // iOS: for unknown reason, when alert or activity controller was presented and we
    // set the UIWindow's root to the root controller that presented that alert,
    // then all the views (and controllers) under the presented alert are removed when the app
    // enters foreground.
    // Dismissing such alerts and controllers after minimizing the app helps.
    open func appEnteredBackground() {
        if let presentedVC = applicationRootViewController?.presentedViewController,
            presentedVC is UIAlertController || presentedVC is UIActivityViewController {
            presentedVC.dismiss(animated: false, completion: nil)
        }
    }

    open func receive(message: [AnyHashable: Any]) {
        DispatchQueue.global.async { [unowned self] in
            do {
                guard let transactionID = try ApplicationServiceRegistry.walletService.receive(message: message),
                    let tx = ApplicationServiceRegistry.walletService.transactionData(transactionID) else { return }
                DispatchQueue.main.async {
                    if let vc = self.navigationController.topViewController as? ReviewTransactionViewController,
                        tx.id == vc.tx.id {
                        vc.update(with: tx)
                    } else if tx.status != .rejected {
                        self.handleIncomingBETransaction(transactionID)
                    }
                }
            } catch WalletApplicationServiceError.validationFailed { // dangerous transaction
                DispatchQueue.main.async {
                    let vc = self.navigationController.topViewController
                    vc?.present(UIAlertController.dangerousTransaction(), animated: true, completion: nil)
                }
            } catch {
                MultisigWalletApplication.ApplicationServiceRegistry.logger.error("Unexpected receive message error",
                                                                                  error: error)
            }
        }
    }

    private func handleIncomingBETransaction(_ transactionID: String) {
        let coordinator = incomingTransactionsManager.coordinator(for: transactionID, source: .browserExtension)
        enterTransactionFlow(coordinator) { [unowned self] in
            self.incomingTransactionsManager.releaseCoordinator(by: coordinator.transactionID)
        }
    }

    private func handleIncomingWalletConnectTransaction(_ transaction: WCPendingTransaction) {
        let rejectHandler: () -> Void = {
            let rejectedError = NSError(domain: "io.gnosis.safe",
                                        code: -401,
                                        userInfo: [NSLocalizedDescriptionKey: "Rejected by user"])
            transaction.completion(.failure(rejectedError))
        }
        let coordinator = incomingTransactionsManager.coordinator(for: transaction.transactionID.id,
                                                                  source: .walletConnect,
                                                                  sourceMeta: transaction.sessionData,
                                                                  onBack: rejectHandler)
        enterTransactionFlow(coordinator) { [unowned self] in
            self.incomingTransactionsManager.releaseCoordinator(by: coordinator.transactionID)
            let hash = ApplicationServiceRegistry.walletService.transactionHash(transaction.transactionID) ?? "0x"
            transaction.completion(.success(hash))
        }
    }

    // Used for incoming transaction and send flow
    fileprivate func enterTransactionFlow(_ flow: FlowCoordinator, completion: (() -> Void)? = nil) {
        saveCheckpoint()
        enter(flow: flow) {
            DispatchQueue.main.async { [unowned self] in
                self.popToLastCheckpoint()
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [unowned self] in
                    self.showTransactionList()
                }
            }
            completion?()
        }
    }

    internal func showTransactionList() {
        if let mainVC = self.navigationController.topViewController as? MainViewController {
            mainVC.showTransactionList()
        }
    }

    func registerForRemoteNotifciations() {
        // notification registration must be on the main thread
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        UIApplication.shared.registerForRemoteNotifications()
        // We need to update push token information with all related app info (client, version, build)
        // on every app start.
        if let token = ApplicationServiceRegistry.walletService.pushToken() {
            updatePushToken(token)
        }
    }

    public func updatePushToken(_ token: String) {
        DispatchQueue.global.async {
            try? ApplicationServiceRegistry.walletService.auth(pushToken: token)
        }
    }

    open func receive(url: URL) {
        walletConnectFlowCoordinator = WalletConnectFlowCoordinator(connectionURL: url)
        self.enter(flow: walletConnectFlowCoordinator)
    }

}

extension MainFlowCoordinator: EventSubscriber {

    // SendTransactionRequested
    public func notify() {
        DispatchQueue.main.async {
            ApplicationServiceRegistry.walletConnectService.popPendingTransactions().forEach {
                self.handleIncomingWalletConnectTransaction($0)
            }
        }
    }

}

extension MainFlowCoordinator: OnboardingWelcomeViewControllerDelegate {

    func didStart() {
        let controller = OnboardingTermsViewController.create()
        controller.delegate = self
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = overlayAnimatorFactory
        rootViewController.definesPresentationContext = true
        presentModally(controller)
    }

}

extension MainFlowCoordinator: OnboardingTermsViewControllerDelegate {

    public func wantsToOpenTermsOfUse() {
        SupportFlowCoordinator(from: self).openTermsOfUse()
    }

    public func wantsToOpenPrivacyPolicy() {
        SupportFlowCoordinator(from: self).openPrivacyPolicy()
    }

    public func didDisagree() {
        dismissModal()
    }

    public func didAgree() {
        dismissModal { [unowned self] in
            self.enter(flow: self.masterPasswordFlowCoordinator) {
                self.switchToRootController()
            }
        }
    }

}

extension MainFlowCoordinator: OnboardingCreateOrRestoreViewControllerDelegate {

    func didSelectNewSafe() {
        enter(flow: newSafeFlowCoordinator) { [unowned self] in
            self.switchToRootController()
        }
    }

    func didSelectRecoverSafe() {
        enter(flow: recoverSafeFlowCoordinator) { [unowned self] in
            self.switchToRootController()
        }
    }

}

extension MainFlowCoordinator: MainViewControllerDelegate {

    func createNewTransaction(token: String) {
        sendFlowCoordinator.token = token
        enterTransactionFlow(sendFlowCoordinator)
    }

    func openMenu() {
        let menuVC = MenuTableViewController.create()
        menuVC.delegate = self
        push(menuVC)
    }

    func manageTokens() {
        enter(flow: manageTokensFlowCoordinator)
    }

    func openAddressDetails() {
        let addressDetailsVC = ReceiveFundsViewController.create()
        push(addressDetailsVC)
    }

    func upgradeContract() {
        saveCheckpoint()
        enter(flow: ContractUpgradeFlowCoordinator()) { [unowned self] in
            DispatchQueue.main.async {
                self.popToLastCheckpoint()
                self.showTransactionList()
            }
        }
    }

}

extension MainFlowCoordinator: TransactionViewViewControllerDelegate {

    public func didSelectTransaction(id: String) {
        let controller = TransactionDetailsViewController.create(transactionID: id)
        controller.delegate = self
        push(controller)
    }

}

extension MainFlowCoordinator: TransactionDetailsViewControllerDelegate {

    public func showTransactionInExternalApp(from controller: TransactionDetailsViewController) {
        SupportFlowCoordinator(from: self).openTransactionBrowser(controller.transactionID!)
    }

}

extension MainFlowCoordinator: MenuTableViewControllerDelegate {

    func didSelectCommand(_ command: MenuCommand) {
        command.run(mainFlowCoordinator: self)
    }

}
