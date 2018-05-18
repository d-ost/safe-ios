//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public struct BlockchainAddress: Hashable, Codable {

    public internal(set) var value: String

    public init(value: String) {
        self.value = value
    }

}
