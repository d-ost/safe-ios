//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

/// These events are still used for funnel testing. They will be removed.
enum OnboardingEvent: String, Trackable {

    case welcome                = "Onboarding_Welcome"
    case setPassword            = "Onboarding_SetPassword"
    case confirmPassword        = "Onboarding_ConfirmPassword"
    case guidelines             = "Onboarding_RecoveryIntro"
    case recoveryPhrase         = "Onboarding_ShowSeed"
    case confirmRecovery        = "Onboarding_EnterSeed"
    case configure              = "Onboarding_Configure"
    case createSafe             = "Onboarding_CreationFee"
    case safeFeePaid            = "Onboarding_FeePaid"

}

/// Tracking events occuring during onboarding flows.
enum OnboardingTrackingEvent: String, ScreenTrackingEvent {

    case welcome                    = "Onboarding_Welcome"
    case terms                      = "Onboarding_Terms"
    case setPassword                = "Onboarding_SetPassword"
    case confirmPassword            = "Onboarding_ConfirmPassword"
    case createOrRestore            = "Onboarding_CreateOrRestore"
    case recoveryIntro              = "Onboarding_RecoveryIntro"
    case showSeed                   = "Onboarding_ShowSeed"
    case enterSeed                  = "Onboarding_EnterSeed"
    case twoFA                      = "Onboarding_2FA"
    case twoFAScan                  = "Onboarding_2FAScan"
    case twoFAScanSuccess           = "Onboarding_2FAScanSuccess"
    case twoFAScanError             = "Onboarding_2FAScanError"
    case createSafeFeeIntro         = "Onboarding_CreationFeeIntro"
    case createSafePaymentMethod    = "Onboarding_PaymentMethod"
    case creationFee                = "Onboarding_CreationFee"
    case feePaid                    = "Onboarding_FeePaid"

}
