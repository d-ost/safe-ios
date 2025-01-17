//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit
import SafeUIKit

// swiftlint:disable line_length
class TextInputViewController: UIViewController {

    @IBOutlet weak var simpleTextInput: TextInput!

    override func viewDidLoad() {
        super.viewDidLoad()
        simpleTextInput.placeholder = "Simple Text Input"
        simpleTextInput.style = .white
    }

    @IBAction func setIconForSimpleTextInput(_ sender: Any) {
        simpleTextInput.leftImage = UIImage(named: "gnosis-icon")
        simpleTextInput.resignFirstResponder()
    }

    @IBAction func removeIconForSimpleTextInput(_ sender: Any) {
        simpleTextInput.leftImage = nil
        simpleTextInput.leftImageURL = nil
        simpleTextInput.resignFirstResponder()
    }

    @IBAction func setIconFromURL(_ sender: Any) {
        simpleTextInput.leftImage = UIImage(named: "default-token")
        simpleTextInput.leftImageURL = URL(string: "https://raw.githubusercontent.com/rmeissner/crypto_resources/master/tokens/rinkeby/icons/0x979861dF79C7408553aAF20c01Cfb3f81CCf9341.png")
    }

    @IBAction func setOpaqueWhite(_ sender: Any) {
        simpleTextInput.style = .opaqueWhite
        simpleTextInput.resignFirstResponder()
    }

    @IBAction func setWhite(_ sender: Any) {
        simpleTextInput.style = .white
        simpleTextInput.resignFirstResponder()
    }

    @IBAction func setGray(_ sender: Any) {
        simpleTextInput.style = .gray
        simpleTextInput.resignFirstResponder()
    }

    @IBAction func resignFirstResponder(_ sender: Any) {
        simpleTextInput.resignFirstResponder()
    }

    @IBAction func toggleClearButton(_ sender: Any) {
        simpleTextInput.hideClearButton = !simpleTextInput.hideClearButton
    }

    @IBAction func setNormalState(_ sender: Any) {
        simpleTextInput.inputState = .normal
    }

    @IBAction func setErrorState(_ sender: Any) {
        simpleTextInput.inputState = .error
    }

    @IBAction func setSuccessState(_ sender: Any) {
        simpleTextInput.inputState = .success
    }

    @IBAction func toggleSuccessIndicator(_ sender: Any) {
        simpleTextInput.showSuccessIndicator = !simpleTextInput.showSuccessIndicator
    }

    @IBAction func toggleCustomRightView(_ sender: Any) {
        if simpleTextInput.customRightView == nil {
            simpleTextInput.customRightView = gnosisRightView()
        } else {
            simpleTextInput.customRightView = nil
        }
    }

    private func gnosisRightView() -> UIView {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 26, height: 14))
        imageView.image = UIImage(named: "gnosis-icon")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

}
