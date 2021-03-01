//
//  AppDelegate.swift
//  Whisper
//
//  Created by Xiao Ling on 5/17/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox

import UserNotifications
import Firebase
import FirebaseStorage
import FirebaseMessaging
import SwiftyStoreKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var badgeCount : Int = 0
    
    /// Allow app to refereence shared variables stored here
    class var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    // push notification info
    var firebaseCloudMessagingToken: String?
    var fireRef: Firestore?
    var storeRef: Storage?
    var application: UIApplication?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.application = application
        FirebaseApp.configure()
        
        application.applicationIconBadgeNumber = 0

        // Create root reference for firebase
        let fire = Firestore.firestore()
        self.fireRef  = fire
        let storage   = Storage.storage()
        self.storeRef = storage
        
        // push notification registeration
        PushNotificationManager.shared.registerForPushNotifications()
        registerForPushNotifications()
        
        // complete any transactions
        // see notes below for the meaning of Atomic / Non-Atomic
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    // Unlock content
                case .failed, .purchasing, .deferred:
                    break // do nothing
                @unknown default:
                    break
                }
            }
        }

        
        return true
    }
    
    func onFire() -> Bool {
        return (self.fireRef != nil)
    }
    
    func canStore() -> Bool{
        return (self.storeRef != nil)
    }
    
    func setBadgeCount( to num : Int? ){
        /*if let n = num {
           self.application?.applicationIconBadgeNumber = n
        }*/
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.-
    }
    
    
}
    
//MARK: - notifications
    

extension AppDelegate: MessagingDelegate, UNUserNotificationCenterDelegate {
    
    func registerForPushNotifications() {
        
        UNUserNotificationCenter.current().delegate = self
        
        UNUserNotificationCenter
            .current()
            .requestAuthorization(options:[.alert, .sound, .badge]) {[weak self] granted, error in
                // Only get the notification settings if user has granted permissions
                guard granted else { return }
                self?.getNotificationSettings()
        }
    }
        
    func getNotificationSettings() {
    
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            
            guard settings.authorizationStatus == .authorized else { return }
            
            Messaging.messaging().delegate = self

            // register with apple
            DispatchQueue.main.async {  UIApplication.shared.registerForRemoteNotifications() }
            
        }
    }

    /*
     @use: When the app is active, and get invite to join event, post
     */
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let payload = notification.request.content.userInfo as! [String:Any?]
        
        if let userId = payload["callerID"] as? String {
            if let action = payload["action"] as? String {

                switch(action){
                case PUSH_ACTION.invite_guest_push_wake:
                    //postLiveInviteFromPushAwake(for: userId)
                    ClubList.shared.pushPriority(at: userId)
                default:
                    break
                }

            }
        
            completionHandler([])
        }
    }

    /*
     @use: When the app is inactive, broadcast notification
     @source: https://firebase.google.com/docs/cloud-messaging/ios/receive#swift:-ios-10
     */
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // note if the app is off line, then this doesn't fire
        let payload = response.notification.request.content.userInfo as! [String:Any?]

        if let gid = payload["callerID"] as? String {
            if let action = payload["action"] as? String {
                switch(action){
                case PUSH_ACTION.invite_guest_push_wake:
                    postLiveInviteFromPushAwake(for: gid)
                default:
                    break
                }
            }
        }
        
        //self.badgeCount += 1
        //self.setBadgeCount(to: self.badgeCount)
        completionHandler()
    }

 }
