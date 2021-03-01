//
//  AskPermissions.swift
//  byte
//
//  Created by Xiao Ling on 5/23/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import Foundation
import UIKit.UIImage
import AVFoundation
import ContactsUI


/*
 @Use: ask for permission from user's:
    - address book
    - camera
    - push notification
 */


func permitAddressBook( _ complete: @escaping Completion ){
    
    let store = CNContactStore()

    if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {

        store.requestAccess(for: .contacts){succ, err in
            if let _ = err {
                DispatchQueue.main.async {
                    return complete(false, "denied with: \(String(describing: err))")
                }
            } else {
                DispatchQueue.main.async {
                    return complete(true,"success")
                }
            }
        }
    } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
        DispatchQueue.main.async {
            return complete(true,"success, already granted")
        }
    }
}


func permitPushNotification( _ complete: @escaping Completion ){
    
    let center = UNUserNotificationCenter.current()

    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        
        if let error = error {
            DispatchQueue.main.async {
                return complete(false,"Denied with: \(error)")
            }
        }
        
        DispatchQueue.main.async {
            return complete(true,"success")
        }
    }

}


func permitAVCapture( _ complete: @escaping Completion ){
    
    switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            DispatchQueue.main.async {
                return complete(true,"success")
            }
        
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        return complete(true,"success")
                    } else {
                        return complete(false,"access denied")
                    }
                }
            }
        
        case .denied: // The user has previously denied access.
            DispatchQueue.main.async {
                return complete(false,"access denied")
            }

        case .restricted: // The user can't grant access due to restrictions.
            DispatchQueue.main.async {
                return complete(false,"access denied")
            }
    @unknown default:
        DispatchQueue.main.async {
            return complete(false,"access denied")
        }
    }

}
