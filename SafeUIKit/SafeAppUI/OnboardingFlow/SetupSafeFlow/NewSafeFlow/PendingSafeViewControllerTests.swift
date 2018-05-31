//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import SafeAppUI
import CommonTestSupport

class PendingSafeViewControllerTests: SafeTestCase {

    //swiftlint:disable:next weak_delegate
    var delegate = MockPendingSafeViewControllerDelegate()
    var controller: PendingSafeViewController!

    override func setUp() {
        super.setUp()
        controller = PendingSafeViewController.create(delegate: delegate)
    }

    func test_canCreate() {
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller)
        XCTAssertNotNil(controller.progressView)
        XCTAssertNotNil(controller.progressStatusLabel)
        XCTAssertNotNil(controller.cancelButton)
        XCTAssertNotNil(controller.titleLabel)
        XCTAssertNotNil(controller.infoLabel)
        XCTAssertNotNil(controller.safeAddressLabel)
    }

    fileprivate func assert(progress percentage: Float, status key: String, line: UInt = #line) {
        controller.loadViewIfNeeded()
        delay()
        XCTAssertEqual(controller.progressView.progress, percentage / 100.0, line: line)
        XCTAssertEqual(controller.progressStatusLabel.text, XCLocalizedString(key), line: line)
    }

    func test_whenAddressNotKnown_thenDisplaysStatus() {
        walletService.startDeployment()
        assert(progress: 10, status: "pending_safe.status.deployment_started")
    }

    func test_whenAddressKnown_thenDisplaysStatus() {
        walletService.startDeployment()
        walletService.assignBlockchainAddress("address")
        assert(progress: 20, status: "pending_safe.status.address_known")
    }

    func test_whenWalletReceivedEnoughFunds_thenDisplaysStatus() {
        walletService.updateMinimumFunding(account: "ETH", amount: 100)
        walletService.update(account: "ETH", newBalance: 100)
        assert(progress: 50, status: "pending_safe.status.account_funded")
    }

    func test_whenNotEnoughFunds_thenDisplaysStatus() {
        walletService.updateMinimumFunding(account: "ETH", amount: 100)
        walletService.update(account: "ETH", newBalance: 90)
        let status = String(format: XCLocalizedString("pending_safe.status.not_enough_funds"), "90 Wei", "100 Wei")
        controller.loadViewIfNeeded()
        delay()
        XCTAssertEqual(controller.progressView.progress, 50.0 / 100.0)
        XCTAssertEqual(controller.progressStatusLabel.text, status)
    }

    func test_whenTransactionSubmitted_thenDisplaysStatus() {
        walletService.markDeploymentAcceptedByBlockchain()
        assert(progress: 80, status: "pending_safe.status.deployment_accepted")
    }

    func test_whenTransactionFailed_thenCallsDelegate() {
        walletService.markDeploymentFailed()
        controller.loadViewIfNeeded()
        delay()
        XCTAssertEqual(delegate.success, false)
    }

    private func assertDisplayedDeploySuccessStatus() {
        assert(progress: 100, status: "pending_safe.status.deployment_success")
    }

    func test_whenTransactionSuccess_thenDisplaysStatus() {
        walletService.markDeploymentSuccess()
        controller.loadViewIfNeeded()
        assertDisplayedDeploySuccessStatus()
    }

    func test_whenTransactionSuccess_thenCallsDelegate() {
        walletService.markDeploymentSuccess()
        controller.loadViewIfNeeded()
        delay()
        XCTAssertEqual(delegate.success, true)
    }

    func test_whenStatusUpdated_thenDisplaysIt() {
        controller.loadViewIfNeeded()
        delay()
        walletService.markDeploymentSuccess()
        assertDisplayedDeploySuccessStatus()
    }

    func test_whenCancels_thenCallsDelegate() {
        controller.loadViewIfNeeded()
        controller.cancel(controller)
        XCTAssertTrue(delegate.cancelled)
    }

}

class MockPendingSafeViewControllerDelegate: PendingSafeViewControllerDelegate {

    var success: Bool?
    var cancelled = false

    func deploymentDidFail() {
        success = false
    }

    func deploymentDidSuccess() {
        success = true
    }

    func deploymentDidCancel() {
        cancelled = true
    }
}
