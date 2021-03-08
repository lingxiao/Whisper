//
//  AuthDelegate.swift
//  byte
//
//  Created by Xiao Ling on 5/17/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth


/*
 @use: all authentication logic is here
 
 */
class AuthDelegate {
    
    static var shared : AuthDelegate = AuthDelegate()
    var window : UIWindow?
    
    var shouldOnBoard: Bool = false
    var provider: OAuthProvider?
    var code: String?
    
    var home: UIViewController?
    var loginController: SplashOne?
    
    var didShowMainApp: Bool = false
    
    init(){
        self.provider = OAuthProvider(providerID: "twitter.com")
    }
    
    //MARK:- unlink app
    
    private func signOut(){
        try! Auth.auth().signOut()
    }
 
    private func unlinkTwitter(){
        Auth.auth().currentUser?.unlink(fromProvider: "twitter.com")
        UserAuthed.shared.unlinkTwitter()
    }
    
    //MARK:- API
    
    func doGoOnBoard(){
        self.shouldOnBoard = true
    }
    
    func doNotOnboard(){
        self.shouldOnBoard = false
    }
    
    func putCode( _ str: String?){
        self.code = str
    }
    
    /*
     @Uese: when authenticated:
        - change root view controller to main app
        - plug all models into backend db
    */
    func onAuthStateChange(withWindow window: UIWindow?) {
        
        self.window = window
        ///signOut()
        ///unlinkTwitter()
        Auth.auth().addStateDidChangeListener { (auth, user) in
             if let user = Auth.auth().currentUser {
                self.syncToDb( with: user.uid ){ return }
                self.showMainApp(withWindow: window){_ in return }
                //self.showIcon(with: window)
            } else {
                self.showLogin(withWindow: window)
            }
        }
    }
    
    // @Use: reconnect to database or connect for the first time
    private func syncToDb( with id: String?, _ then: @escaping () -> Void ){
        guard let id = id else { return }
        UserAuthed.shared.syncToRemote( with: id ){
            UserList.shared.await()
            WhisperGraph.shared.await()
            ClubList.shared.await()
            WhisperAnalytics.shared.await()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                WhisperCalendar.shared.await()
            }
            then()
        }
    }
    
    //MARK:- attach home view

    private func showIcon(with window: UIWindow?) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let icon = storyboard.instantiateViewController(withIdentifier: "Icon")
        window?.rootViewController = nil
        window?.rootViewController = icon
    }
    
    private func showLogin(withWindow window: UIWindow?) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let login = storyboard.instantiateViewController(withIdentifier: "SignIn")
        let nav = UINavigationController()
        nav.setNavigationBarHidden(true, animated: true)
        nav.viewControllers = [ login ]
        window?.rootViewController = nil
        window?.rootViewController = nav
        self.loginController = login as? SplashOne
    }

    // @use: instantiate base app and attach navigation controller    // https://stackoverflow.com/questions/28793331/creating-a-navigationcontroller-programmatically-swift
    private func showMainApp(withWindow window: UIWindow?, _ then: @escaping (HomeController?) -> Void) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let homeViewController = storyboard.instantiateViewController(withIdentifier: "Home")
        let nav = UINavigationController()
        nav.setNavigationBarHidden(true, animated: false)
        nav.viewControllers = [ homeViewController ]
        window?.rootViewController = nil
        window?.rootViewController = nav
        then( homeViewController as? HomeController)
        self.home = homeViewController
    }
    
    
    //MARK:- authenticate8

    func authenticate( with email: String, phone: String?,  _ complete: @escaping (Bool, String) -> Void){

        let password = generatePassword(email: email)
        
        /*
            janedo@playhouse.social 64439638952027_laicos.esuohyalp@odenaj_1904383418681
        */
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            
            // guard let _ = self else { return complete(false, "Login error") }

            if let error = error {

                if let errCode = AuthErrorCode(rawValue: error._code) {
                    
                    switch(errCode){
                        case .userNotFound:
                            AuthDelegate.shared.signUp(
                                   with: email
                                 , password: password
                                 , phone: phone
                             ){ ( succ, msg ) in complete( succ, msg) }
                        case .accountExistsWithDifferentCredential:
                            complete(false,"accountExistsWithDifferentCredential")
                              //print("0- Indicates account linking is required.")
                        case .adminRestrictedOperation:
                            complete(false,"adminRestrictedOperation")
                              //print("1- Indicates that the operation is admin restricted.")
                        case .appNotAuthorized:
                            complete(false,"appNotAuthorized")
                              //print("2- Indicates the App is not authorized to use Firebase Authentication with the provided API Key.")
                        case .appNotVerified:
                            complete(false,"appNotVerified")
                              //print("3- Indicates that the app could not be verified by Firebase during phone number authentication.")
                        case .appVerificationUserInteractionFailure:
                            complete(false,"appVerificationUserInteractionFailure")
                              //print("4- Indicates a general failure during the app verification flow.")
                        case .captchaCheckFailed:
                            complete(false,"captchaCheckFailed")
                              //print("5- Indicates that the reCAPTCHA token is not valid.")
                        case .credentialAlreadyInUse:
                            complete(false,"credentialAlreadyInUse")
                              //print("6- Indicates an attempt to link with a credential that has already been linked with a different Firebase account")
                        case .customTokenMismatch:
                            complete(false,"customTokenMismatch")
                              //print("7- Indicates the service account and the API key belong to different projects.")
                        case .dynamicLinkNotActivated:
                            complete(false,"dynamicLinkNotActivated")
                              //print("8- Indicates that a Firebase Dynamic Link is not activated.")
                        case .emailAlreadyInUse:
                            complete(false,"emailAlreadyInUse")
                              //print("9- Indicates the email used to attempt a sign up is already in use.")
                        case .emailChangeNeedsVerification:
                            complete(false,"emailChangeNeedsVerification")
                              //print("10- Indicates that the a verifed email is required to changed to.")
                        case .expiredActionCode:
                            complete(false,"expiredActionCode")
                              //print("11- Indicates the OOB code is expired.")
                        case .gameKitNotLinked:
                            complete(false,"gameKitNotLinked")
                              //print("12- Indicates that the GameKit framework is not linked prior to attempting Game Center signin.")
                        case .internalError:
                            complete(false,"internalError")
                              //print("13- Indicates an internal error occurred.")
                        case .invalidActionCode:
                            complete(false,"invalidActionCode")
                              //print("15- Indicates the OOB code is invalid.")
                        case .invalidAPIKey:
                            complete(false,"invalidAPIKey")
                              //print("15- Indicates an invalid API key was supplied in the request.")
                        case .invalidAppCredential:
                            complete(false,"invalidAppCredential")
                              //print("16- Indicates that an invalid APNS device token was used in the verifyClient request.")
                        case .invalidClientID:
                            complete(false,"invalidClientID")
                              //print("17- Indicates that the clientID used to invoke a web flow is invalid.")
                        case .invalidContinueURI:
                            complete(false,"invalidContinueURI")
                              //print("18- Indicates that the domain specified in the continue URI is not valid.")
                        case .invalidCredential:
                            complete(false,"invalidCredential")
                              //print("19- Indicates the IDP token or requestUri is invalid.")
                        case .invalidCustomToken:
                            complete(false,"invalidCustomToken")
                              //print("20- Indicates a validation error with the custom token.")
                        case .invalidDynamicLinkDomain:
                              //print("21- Indicates that the Firebase Dynamic Link domain used is either not configured or is unauthorized for the current project.")
                            complete(false,"invalidDynamicLinkDomain")
                        case .invalidEmail:
                              //print("22- Indicates the email is invalid.")
                            complete(false,"invalidEmail")
                        case .invalidMessagePayload:
                            complete(false,"invalidMessagePayload")
                              //print("23- Indicates that there are invalid parameters in the payload during a 'send password reset email' attempt.")
                        case .invalidMultiFactorSession:
                              //print("24- Indicates that the multi factor session is invalid.")
                            complete(false,"invalidMultiFactorSession")
                        case .invalidPhoneNumber:
                              //print("25- Indicates that an invalid phone number was provided in a call to verifyPhoneNumber:completion:.")
                            complete(false,"invalidPhoneNumber")
                        case .invalidProviderID:
                            complete(false,"invalidProviderID")
                              //print("26- Represents the error code for when the given provider id for a web operation is invalid.")
                        case .invalidRecipientEmail:
                            complete(false,"invalidRecipientEmail")
                              //print("27- Indicates that the recipient email is invalid.")
                        case .invalidSender:
                            complete(false,"invalidSender")
                              //print("28- Indicates that the sender email is invalid during a “send password reset email” attempt.")
                        case .invalidUserToken:
                            complete(false,"invalidUserToken")
                              //print("29- Indicates user’s saved auth credential is invalid, the user needs to sign in again.")
                        case .invalidVerificationCode:
                            complete(false,"invalidVerificationCode")
                              //print("30- Indicates that an invalid verification code was used in the verifyPhoneNumber request.")
                        case .invalidVerificationID:
                            complete(false,"invalidVerificationID")
                              //print("31- Indicates that an invalid verification ID was used in the verifyPhoneNumber request.")
                        case .keychainError:
                            complete(false,"keychainError")
                              //print("32- Indicates an error occurred while attempting to access the keychain.")
                        case .localPlayerNotAuthenticated:
                            complete(false,"localPlayerNotAuthenticated")
                              //print("33- Indicates that the local player was not authenticated prior to attempting Game Center signin.")
                        case .maximumSecondFactorCountExceeded:
                            complete(false,"maximumSecondFactorCountExceeded")
                              //print("34- Indicates that the maximum second factor count is exceeded.")
                        case .malformedJWT:
                            complete(false,"malformedJWT")
                              //print("35- Raised when a JWT fails to parse correctly. May be accompanied by an underlying error describing which step of the JWT parsing process failed.")
                        case .missingAndroidPackageName:
                            complete(false,"missingAndroidPackageName")
                              //print("36- Indicates that the android package name is missing when the androidInstallApp flag is set to true.")
                        case .missingAppCredential:
                            complete(false,"missingAppCredential")
                              //print("37- Indicates that the APNS device token is missing in the verifyClient request.")
                        case .missingAppToken:
                            complete(false,"missingAppToken")
                              //print("38- Indicates that the APNs device token could not be obtained. The app may not have set up remote notification correctly, or may fail to forward the APNs device token to FIRAuth if app delegate swizzling is disabled.")
                        case .missingContinueURI:
                            complete(false,"missingContinueURI")
                              //print("39- Indicates that a continue URI was not provided in a request to the backend which requires one.")
                        case .missingClientIdentifier:
                            complete(false,"missingClientIdentifier")
                              //print("40- Indicates an error for when the client identifier is missing.")
                        case .missingEmail:
                            complete(false,"missingEmail")
                              //print("41- Indicates that an email address was expected but one was not provided.")
                        case .missingIosBundleID:
                              //print("42- Indicates that the iOS bundle ID is missing when a iOS App Store ID is provided.")
                            complete(false,"missingIosBundleID")
                        case .missingMultiFactorSession:
                            complete(false,"missingMultiFactorSession")
                              //print("43- Indicates that the multi factor session is missing.")
                        case .missingOrInvalidNonce:
                              //print("44- Indicates that the nonce is missing or invalid.")
                            complete(false,"missingOrInvalidNonce")
                        case .missingPhoneNumber:
                            complete(false,"missingPhoneNumber")
                              //print("45- Indicates that a phone number was not provided in a call to verifyPhoneNumber:completion.")
                        case .missingVerificationCode:
                              //print("46- Indicates that the phone auth credential was created with an empty verification code.")
                            complete(false,"missingVerificationCode")
                        case .missingVerificationID:
                            complete(false,"missingVerificationID")
                              //print("47- Indicates that the phone auth credential was created with an empty verification ID.")
                        case .missingMultiFactorInfo:
                              //print("48- Indicates that the multi factor info is missing.")
                            complete(false,"missingMultiFactorInfo")
                        case .multiFactorInfoNotFound:
                            complete(false,"multiFactorInfoNotFound")
                              //print("49- Indicates that the multi factor info is not found.")
                        case .networkError:
                              //print("50- Indicates a network error occurred (such as a timeout, interrupted connection, or unreachable host). These types of errors are often recoverable with a retry. The NSUnderlyingError field in the NSError.userInfo dictionary will contain the error encountered.")
                            complete(false,"networkError")
                        case .noSuchProvider:
                            complete(false,"noSuchProvider")
                              //print("51- Indicates an attempt to unlink a provider that is not linked.")
                        case .notificationNotForwarded:
                            complete(false,"notificationNotForwarded")
                              //print("52- Indicates that the app fails to forward remote notification to FIRAuth.")
                        case .nullUser:
                              //print("53- Indicates that a non-null user was expected as an argmument to the operation but a null user was provided.")
                            complete(false,"nullUser")
                         case .operationNotAllowed:
                              //print("54- Indicates the administrator disabled sign in with the specified identity provider.")
                            complete(false,"operationNotAllowed")
                        case .providerAlreadyLinked:
                            complete(false,"providerAlreadyLinked")
                              //print("55- Indicates an attempt to link a provider to which the account is already linked.")
                        case .quotaExceeded:
                              //print("56- Indicates that the quota of SMS messages for a given project has been exceeded.")
                            complete(false,"quotaExceeded")
                        case .rejectedCredential:
                            complete(false,"rejectedCredential")
                              //print("57- Indicates that the credential is rejected because it’s misformed or mismatching.")
                        case .requiresRecentLogin:
                            complete(false,"")
                              //print("58- Indicates the user has attemped to change email or password more than 5 minutes after signing in.")
                        case .secondFactorAlreadyEnrolled:
                              //print("59- Indicates that the second factor is already enrolled.")
                            complete(false,"")
                        case .secondFactorRequired:
                              //print("60- Indicates that the second factor is required for signin.")
                            complete(false,"")
                        case .sessionExpired:
                            complete(false,"")
                              //print("61- Indicates that the SMS code has expired.")
                        case .tooManyRequests:
                              //print("62- Indicates that too many requests were made to a server method.")
                            complete(false,"")
                        case .unauthorizedDomain:
                              //print("63- Indicates that the domain specified in the continue URL is not whitelisted in the Firebase console.")
                            complete(false,"")
                        case .unsupportedFirstFactor:
                            complete(false,"")
                              //print("64- Indicates that the first factor is not supported.")
                        case .unverifiedEmail:
                              //print("65- Indicates that the email is required for verification.")
                            complete(false,"")
                        case .userDisabled:
                              //print("66- Indicates the user’s account is disabled on the server.")
                            complete(false,"")
                        case .userMismatch:
                            complete(false,"")
                              //print("67- Indicates that an attempt was made to reauthenticate with a user which is not the current user.")
                        case .userTokenExpired:
                              //print("69- Indicates the saved token has expired, for example, the user may have changed account password on another device. The user needs to sign in again on the device that made this request.")
                            complete(false,"")
                        case .weakPassword:
                              //print("70- Indicates an attempt to set a password that is considered too weak.")
                            complete(false,"")
                        case .webContextAlreadyPresented:
                            complete(false,"")
                              //print("71- Indicates that an attempt was made to present a new web context while one was already being presented.")
                        case .webContextCancelled:
                            complete(false,"")
                              //print("72- Indicates that the URL presentation was cancelled prematurely by the user.")
                        case .webInternalError:
                            complete(false,"")
                              //print("73- Indicates that an internal error occurred within a SFSafariViewController or WKWebView.")
                        case .webNetworkRequestFailed:
                            complete(false,"")
                              //print("74- Indicates that a network request within a SFSafariViewController or WKWebView failed.")
                        case .wrongPassword:
                            //print("75- Indicates the user attempted sign in with a wrong password.")
                            complete(false,"Invalid credentials. You may have to checkin with your organization's administrator")
                        case .webSignInUserInteractionFailure:
                              //print("76- Indicates a general failure during a web sign-in flow.")
                            complete(false,"")
                        default:
                              //print("77- Unknown error occurred")
                            complete(false,"Unknown error")
                    }
                }
            } else {
                complete(true, "signed in!")
                return
            }

        }
    }
    
    
    func signUp( with email: String, password: String, phone: String?, _ complete: @escaping (Bool, String) -> Void){

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            
            if ( error == nil ){

                complete( true, "Ok! one moment..." )
                UserAuthed.createUser( with: email, phone: phone ){ (succ, msg) in return }

            } else {
                
                if let error = error {

                    if let errCode = AuthErrorCode(rawValue: error._code) {
                        switch(errCode){
                        case .accountExistsWithDifferentCredential:
                            break  //print("0- Indicates account linking is required.")
                        case .adminRestrictedOperation:
                            break  //print("1- Indicates that the operation is admin restricted.")
                        case .appNotAuthorized:
                            break  //print("2- Indicates the App is not authorized to use Firebase Authentication with the provided API Key.")
                        case .appNotVerified:
                            break  //print("3- Indicates that the app could not be verified by Firebase during phone number authentication.")
                        case .appVerificationUserInteractionFailure:
                            break  //print("4- Indicates a general failure during the app verification flow.")
                        case .captchaCheckFailed:
                            break  //print("5- Indicates that the reCAPTCHA token is not valid.")
                        case .credentialAlreadyInUse:
                            break  //print("6- Indicates an attempt to link with a credential that has already been linked with a different Firebase account")
                        case .customTokenMismatch:
                            break  //print("7- Indicates the service account and the API key belong to different projects.")
                        case .dynamicLinkNotActivated:
                            break  //print("8- Indicates that a Firebase Dynamic Link is not activated.")
                        case .emailAlreadyInUse:
                            break  //print("9- Indicates the email used to attempt a sign up is already in use.")
                        case .emailChangeNeedsVerification:
                            break  //print("10- Indicates that the a verifed email is required to changed to.")
                        case .expiredActionCode:
                            break  //print("11- Indicates the OOB code is expired.")
                        case .gameKitNotLinked:
                            break  //print("12- Indicates that the GameKit framework is not linked prior to attempting Game Center signin.")
                        case .internalError:
                            break  //print("13- Indicates an internal error occurred.")
                        case .invalidActionCode:
                            break  //print("15- Indicates the OOB code is invalid.")
                        case .invalidAPIKey:
                            break  //print("15- Indicates an invalid API key was supplied in the request.")
                        case .invalidAppCredential:
                            break  //print("16- Indicates that an invalid APNS device token was used in the verifyClient request.")
                        case .invalidClientID:
                            break  //print("17- Indicates that the clientID used to invoke a web flow is invalid.")
                        case .invalidContinueURI:
                            break  //print("18- Indicates that the domain specified in the continue URI is not valid.")
                        case .invalidCredential:
                            break  //print("19- Indicates the IDP token or requestUri is invalid.")
                        case .invalidCustomToken:
                            break  //print("20- Indicates a validation error with the custom token.")
                        case .invalidDynamicLinkDomain:
                            break  //print("21- Indicates that the Firebase Dynamic Link domain used is either not configured or is unauthorized for the current project.")
                        case .invalidEmail:
                            break  //print("22- Indicates the email is invalid.")
                        case .invalidMessagePayload:
                            break  //print("23- Indicates that there are invalid parameters in the payload during a 'send password reset email' attempt.")
                        case .invalidMultiFactorSession:
                            break  //print("24- Indicates that the multi factor session is invalid.")
                        case .invalidPhoneNumber:
                            break  //print("25- Indicates that an invalid phone number was provided in a call to verifyPhoneNumber:completion:.")
                        case .invalidProviderID:
                            break  //print("26- Represents the error code for when the given provider id for a web operation is invalid.")
                        case .invalidRecipientEmail:
                            break  //print("27- Indicates that the recipient email is invalid.")
                        case .invalidSender:
                            break  //print("28- Indicates that the sender email is invalid during a “send password reset email” attempt.")
                        case .invalidUserToken:
                            break  //print("29- Indicates user’s saved auth credential is invalid, the user needs to sign in again.")
                        case .invalidVerificationCode:
                            break  //print("30- Indicates that an invalid verification code was used in the verifyPhoneNumber request.")
                        case .invalidVerificationID:
                            break  //print("31- Indicates that an invalid verification ID was used in the verifyPhoneNumber request.")
                        case .keychainError:
                            break  //print("32- Indicates an error occurred while attempting to access the keychain.")
                        case .localPlayerNotAuthenticated:
                            break  //print("33- Indicates that the local player was not authenticated prior to attempting Game Center signin.")
                        case .maximumSecondFactorCountExceeded:
                            break  //print("34- Indicates that the maximum second factor count is exceeded.")
                        case .malformedJWT:
                            break  //print("35- Raised when a JWT fails to parse correctly. May be accompanied by an underlying error describing which step of the JWT parsing process failed.")
                        case .missingAndroidPackageName:
                            break  //print("36- Indicates that the android package name is missing when the androidInstallApp flag is set to true.")
                        case .missingAppCredential:
                            break  //print("37- Indicates that the APNS device token is missing in the verifyClient request.")
                        case .missingAppToken:
                            break  //print("38- Indicates that the APNs device token could not be obtained. The app may not have set up remote notification correctly, or may fail to forward the APNs device token to FIRAuth if app delegate swizzling is disabled.")
                        case .missingContinueURI:
                            break  //print("39- Indicates that a continue URI was not provided in a request to the backend which requires one.")
                        case .missingClientIdentifier:
                            break  //print("40- Indicates an error for when the client identifier is missing.")
                        case .missingEmail:
                            break  //print("41- Indicates that an email address was expected but one was not provided.")
                        case .missingIosBundleID:
                            break  //print("42- Indicates that the iOS bundle ID is missing when a iOS App Store ID is provided.")
                        case .missingMultiFactorSession:
                            break  //print("43- Indicates that the multi factor session is missing.")
                        case .missingOrInvalidNonce:
                            break  //print("44- Indicates that the nonce is missing or invalid.")
                        case .missingPhoneNumber:
                            break  //print("45- Indicates that a phone number was not provided in a call to verifyPhoneNumber:completion.")
                        case .missingVerificationCode:
                            break  //print("46- Indicates that the phone auth credential was created with an empty verification code.")
                        case .missingVerificationID:
                            break  //print("47- Indicates that the phone auth credential was created with an empty verification ID.")
                        case .missingMultiFactorInfo:
                            break  //print("48- Indicates that the multi factor info is missing.")
                        case .multiFactorInfoNotFound:
                            break  //print("49- Indicates that the multi factor info is not found.")
                        case .networkError:
                            break  //print("50- Indicates a network error occurred (such as a timeout, interrupted connection, or unreachable host). These types of errors are often recoverable with a retry. The NSUnderlyingError field in the NSError.userInfo dictionary will contain the error encountered.")
                        case.noSuchProvider:
                            break  //print("51- Indicates an attempt to unlink a provider that is not linked.")
                        case .notificationNotForwarded:
                            break  //print("52- Indicates that the app fails to forward remote notification to FIRAuth.")
                        case .nullUser:
                            break  //print("53- Indicates that a non-null user was expected as an argmument to the operation but a null user was provided.")
                        case .operationNotAllowed:
                            break  //print("54- Indicates the administrator disabled sign in with the specified identity provider.")
                        case .providerAlreadyLinked:
                            break  //print("55- Indicates an attempt to link a provider to which the account is already linked.")
                        case .quotaExceeded:
                            break  //print("56- Indicates that the quota of SMS messages for a given project has been exceeded.")
                        case .rejectedCredential:
                            break  //print("57- Indicates that the credential is rejected because it’s misformed or mismatching.")
                        case .requiresRecentLogin:
                            break  //print("58- Indicates the user has attemped to change email or password more than 5 minutes after signing in.")
                        case .secondFactorAlreadyEnrolled:
                            break  //print("59- Indicates that the second factor is already enrolled.")
                        case .secondFactorRequired:
                            break  //print("60- Indicates that the second factor is required for signin.")
                        case .sessionExpired:
                            break  //print("61- Indicates that the SMS code has expired.")
                        case .tooManyRequests:
                            break  //print("62- Indicates that too many requests were made to a server method.")
                        case .unauthorizedDomain:
                            break  //print("63- Indicates that the domain specified in the continue URL is not whitelisted in the Firebase console.")
                        case .unsupportedFirstFactor:
                            break  //print("64- Indicates that the first factor is not supported.")
                        case .unverifiedEmail:
                            break  //print("65- Indicates that the email is required for verification.")
                        case .userDisabled:
                            break  //print("66- Indicates the user’s account is disabled on the server.")
                        case .userMismatch:
                            break  //print("67- Indicates that an attempt was made to reauthenticate with a user which is not the current user.")
                        case .userNotFound:
                            break  //print("68- Indicates the user account was not found.")
                        case .userTokenExpired:
                            break  //print("69- Indicates the saved token has expired, for example, the user may have changed account password on another device. The user needs to sign in again on the device that made this request.")
                        case .weakPassword:
                            break  //print("70- Indicates an attempt to set a password that is considered too weak.")
                        case .webContextAlreadyPresented:
                            break  //print("71- Indicates that an attempt was made to present a new web context while one was already being presented.")
                        case .webContextCancelled:
                            break  //print("72- Indicates that the URL presentation was cancelled prematurely by the user.")
                        case .webInternalError:
                            break  //print("73- Indicates that an internal error occurred within a SFSafariViewController or WKWebView.")
                        case .webNetworkRequestFailed:
                            break  //print("74- Indicates that a network request within a SFSafariViewController or WKWebView failed.")
                        case .wrongPassword:
                            break  //print("75- Indicates the user attempted sign in with a wrong password.")
                        case .webSignInUserInteractionFailure:
                            break  //print("76- Indicates a general failure during a web sign-in flow.")
                        default:
                            break  //print("77- Unknown error occurred")
                            
                        }
                    }
                } else {
                    complete(false,"Network error")
                }
            }
        }
    }

    
    /*
     @use: authenticate with twitter and get:
        - access token
        - access secret
     */
    public func linkTwitter( _ then: @escaping (Bool,String) -> Void ){
        
        provider?.getCredentialWith(nil) { credential, error in
            
            if let err = error {
                return then(false, err.localizedDescription)
            }

            if let cred = credential {
                
                Auth.auth().currentUser?.link(with: cred) { authResult, error in
                    
                    if let res = authResult {
                        
                        var screen_name : String = ""
                        var id : Int = 0
                        

                        if let info = res.additionalUserInfo {
                            if let profile = info.profile {
                                screen_name = unsafeCastString(profile["screen_name"])
                                id = unsafeCastInt(profile["id"])
                            }
                        }
                        
                        if let dict = res.credential?.dictionaryWithValues(forKeys: [
                              "secret"
                            , "accessToken"
                        ]) {
                            
                            if let sec = dict["secret"] as? String {
                                
                                if let tok = dict["accessToken"] as? String {

                                    UserAuthed.shared
                                        .saveTwitter(
                                              secret: sec
                                            , accessToken: tok
                                            , screen_name: screen_name
                                            , twitterId: id
                                        ){succ in
                                                then(succ, "Saved with: \(succ)")
                                            }
                                } else {

                                    then(false, "No token")
                                }
                                
                            } else {
                                
                                then(false, "no secret")
                            }
                            
                            
                        } else {
                            
                            return then(false, "cannot retrieve secret and access-token")
                        }
                        
                        
                    } else if let err = error {
                        
                        return then(false, "\(err.localizedDescription)")
                         
                    } else {
                        
                        return then(false, "Unknown rror")
                    }

                    
                }
                
            } else {
                
                return then(false, "No credentials")
            }
        }
        
    }

    
}
