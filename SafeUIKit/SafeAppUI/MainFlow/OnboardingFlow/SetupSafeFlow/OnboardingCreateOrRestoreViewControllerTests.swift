//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import SafeAppUI
import CommonTestSupport

class OnboardingCreateOrRestoreViewControllerTests: SafeTestCase {

    // swiftlint:disable:next weak_delegate
    let delegate = MockOnboardingCreateOrRestoreViewControllerDelegate()
    var vc: OnboardingCreateOrRestoreViewController!

    override func setUp() {
        super.setUp()
        vc = OnboardingCreateOrRestoreViewController.create(delegate: delegate)
        vc.loadViewIfNeeded()
    }

    func test_canCreate() {
        XCTAssertNotNil(vc.headerLabel)
        XCTAssertNotNil(vc.newSafeButton)
    }

    func test_whenNewSafeButtonPressed_thenDelegateCalled() {
        XCTAssertFalse(delegate.pressedNewSafe)
        vc.createNewSafe(self)
        XCTAssertTrue(delegate.pressedNewSafe)
    }

    func test_whenNewSafeButtonPressed_thenNewWalletCreated() {
        walletService.expect_hasSelectedWallet(false)
        vc.createNewSafe(vc as Any)
        XCTAssertTrue(walletService.didCreateNewDraft)
    }

    func test_whenNewSafeButtonPressedTwice_thenExistingDraftWalletIsUsed() {
        vc.createNewSafe(vc as Any)
        walletService.didCreateNewDraft = false
        vc.createNewSafe(vc as Any)
        XCTAssertFalse(walletService.didCreateNewDraft)
    }

    func test_tracking() {
        XCTAssertTracksAppearance(in: vc, OnboardingTrackingEvent.createOrRestore)
    }
}

final class MockOnboardingCreateOrRestoreViewControllerDelegate: OnboardingCreateOrRestoreViewControllerDelegate {

    var pressedNewSafe = false
    var pressedRecovery = false

    func didSelectNewSafe() {
        pressedNewSafe = true
    }

    func didSelectRecoverSafe() {
        pressedRecovery = true
    }

    func openMenu() {}

}
