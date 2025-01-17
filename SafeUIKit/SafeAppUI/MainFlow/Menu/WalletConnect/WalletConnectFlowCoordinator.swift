//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import MultisigWalletApplication
import BigInt

final class WalletConnectFlowCoordinator: FlowCoordinator {

    weak var sessionListController: WCSessionListTableViewController?
    weak var onboardingController: OnboardingViewController?

    /// URL to connect to when the flow coordinator opens session list (even after onboarding).
    ///
    /// We defer connecting to this URL until the session list screen is shown because before that
    /// the UI is not properly intiialized to show error or other information.
    private var connectionURL: URL?

    convenience init(connectionURL url: URL?, rootViewController: UIViewController? = nil) {
        self.init(rootViewController: rootViewController)
        self.connectionURL = url
    }

    override func setUp() {
        super.setUp()
        if ApplicationServiceRegistry.walletConnectService.isOnboardingDone() {
            showSessionList()
        } else {
            showOnboarding()
        }
    }

    func showOnboarding() {
        let vc = OnboardingViewController.create(next: { [weak self] in
            self?.onboardingController?.transitionToNextPage()
        }, finish: { [weak self] in
            self?.finishOnboarding()
        })
        push(vc)
        onboardingController = vc
    }

    func finishOnboarding() {
        ApplicationServiceRegistry.walletConnectService.markOnboardingDone()
        showSessionList()
        // waiting for showSessionList animation completion
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
            self?.showScan()
        }
        removeViewControllerFromNavigationStack(onboardingController)
    }

    func showScan() {
        sessionListController?.scan()
    }

    func showSessionList() {
        let vc = WCSessionListTableViewController(connectionURL: connectionURL)
        push(vc)
        sessionListController = vc
    }

}

fileprivate extension OnboardingViewController {

    static func create(next: @escaping () -> Void, finish: @escaping () -> Void) -> OnboardingViewController {
        let nextActionTitle = LocalizedString("next", comment: "Next")
        return .create(steps: [
            .init(image: Asset.WalletConnect._1.image,
                  title: LocalizedString("welcome_to_walletconnect", comment: "Onboarding 1 title"),
                  description: LocalizedString("walletconnect_is", comment: "Onboarding 1 description"),
                  actionTitle: nextActionTitle,
                  trackingEvent: WCTrackingEvent.onboarding1,
                  action: next),
            .init(image: Asset.WalletConnect._2.image,
                  title: LocalizedString("how_does_it_work", comment: "Onboarding 2 title"),
                  description: LocalizedString("you_can_manage_connections", comment: "Onboarding 2 description"),
                  actionTitle: nextActionTitle,
                  trackingEvent: WCTrackingEvent.onboarding2,
                  action: next),
            .init(image: Asset.WalletConnect._3.image,
                  title: LocalizedString("lets_get_started", comment: "Onboarding 3 title"),
                  description: LocalizedString("to_connect_to_dapp", comment: "Onboarding 3 description"),
                  actionTitle: LocalizedString("get_started", comment: "Start button title"),
                  trackingEvent: WCTrackingEvent.onboarding3,
                  action: finish)
        ])
    }

}
