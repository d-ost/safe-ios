//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public class WalletProxyContractProxy: EthereumContractProxy {

    /// Returns address of the masterCopy contract
    public func masterCopyAddress() throws -> Address? {
        // masterCopy is a 1st variable of the contract, so we can fetch its value directly from contract's storage.
        // https://github.com/gnosis/gnosis-py/blob/a7bb8865dc5424c44bcb7ad5f11dee4f491acffb/gnosis/safe/safe.py#L445
        let data = try nodeService.eth_getStorageAt(address: contract, position: 0)
        return decodeAddress(data)
    }

    private static let changeMasterCopySignature = "changeMasterCopy(address)"

    public func changeMasterCopy(_ address: Address) -> Data {
        return invocation(WalletProxyContractProxy.changeMasterCopySignature, encodeAddress(address))
    }

    public func decodeChangeMasterCopyArguments(from data: Data) -> Address? {
        let selector = method(WalletProxyContractProxy.changeMasterCopySignature)
        guard data.starts(with: selector) else { return nil }
        var input = data
        input.removeFirst(selector.count)
        let newAddress = decodeAddress(input)
        return newAddress
    }

}
