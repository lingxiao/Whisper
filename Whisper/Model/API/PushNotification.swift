//
//  PushNotification.swift
//  byte
//
//  Created: https://www.iosapptemplates.com/blog/ios-development/push-notifications-firebase-swift-5
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications


// @source: https://console.firebase.google.com/u/0/project/play-house-social/settings/cloudmessaging/ios:com.byteme.meme
let SERVER_KEY = "AAAAVQdxgQc:APA91bFSnFbelIu_zU8eBhvbbhaPKldCnKHxCkQRLFl5aH2iAU4DLYQZfBoGyNvzaTkvJJ5ds_gRAAw28cvs2BIGZn32jEqivFotrNlVUiNDktLhvANNVigcFzus2rXMmnEa4PBP2wqx"

class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    static var shared : PushNotificationManager = PushNotificationManager()

    func registerForPushNotifications() {

         if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { res, err in return })
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        UIApplication.shared.registerForRemoteNotifications()
        updateFirestorePushTokenIfNeeded()
    }
    
    
    func updateFirestorePushTokenIfNeeded() {
        if let token = Messaging.messaging().fcmToken {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0 ) { [weak self] in
                UserAuthed.shared.changeToken(to: token){(succ,msg) in return }
            }
        }
    }
    
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        updateFirestorePushTokenIfNeeded()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    }
    
    func sendPushNotification(
          to token  : String
        , title     : String
        , body      : String
        , payload   : [String:String]
        , _ complete: @escaping(Bool, String) -> Void
    ){

        
        let serverKey = SERVER_KEY
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        
        // re-cast payload as string:string or firebase will not send message
        let _payload: [String:String] = payload as [String:String]
        
        let paramString: [String : Any] = [
              "to" : token
            , "notification" : [
                 "title" : title
                , "body" : body
            ]
            // Apple specific settings
            , "apns": [
                "headers": [ "apns-priority": "10"]
                , "payload": [
                    "aps": [ "sound": "default", "badge": 1  ]
                ],
            ]
            , "data": _payload
        ]
        

        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
        
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in do {

            if let jsonData = data {

                if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options:
                    
                    JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        
                        let fail = jsonDataDict["failure"]
                        let succ = jsonDataDict["success"]
                        
                        let did_succ = fail != nil
                            && succ != nil
                            && Int(truncating: succ! as! NSNumber) == 1
                            && Int(truncating: fail! as! NSNumber) == 0
                    
                        DispatchQueue.main.async {
                            complete(did_succ, "sent with: \(jsonDataDict)")
                        }
                    
                } else {
                    
                    DispatchQueue.main.async {
                        complete(false, "failed to serialize jsondict")
                    }
                }

            }
        } catch let err as NSError {
            DispatchQueue.main.async {
                complete(false,"failed to send message due to \(err.debugDescription)")
            }
        }
        }
        task.resume()
        
    }
    
}
