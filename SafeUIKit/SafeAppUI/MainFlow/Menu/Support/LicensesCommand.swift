//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

final class LicensesCommand: MenuCommand {

    override var title: String {
        return LocalizedString("licenses", comment: "Licenses")
    }

    override func run(mainFlowCoordinator: MainFlowCoordinator) {
        SupportFlowCoordinator(from: mainFlowCoordinator).openLicenses()
    }

}
