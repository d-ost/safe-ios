//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import MultisigWalletDomainModel

public class InMemoryExternallyOwnedAccountRepository: ExternallyOwnedAccountRepository {

    private var accounts = [Address: ExternallyOwnedAccount]()

    public init () {}

    public func save(_ account: ExternallyOwnedAccount) throws {
        accounts[account.address] = account
    }

    public func remove(address: Address) throws {
        accounts.removeValue(forKey: address)
    }

    public func find(by address: Address) throws -> ExternallyOwnedAccount? {
        return accounts[address]
    }

}
