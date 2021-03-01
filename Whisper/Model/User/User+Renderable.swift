//
//  User+Renderable.swift
//  byte
//
//  Created by Xiao Ling on 7/3/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
// import MessengerKit
import UIKit

extension User: Renderable {
    
    func get_H1() -> String {
        return unsafeCastString(self.name)
    }
    
    func get_H2() -> String {
        return self.bio
    }
    
    func get_H2_alt() -> String {
        return ""
    }
    
    func fetchThumbURL() -> URL? {
        return self.thumbURL
    }
    
    func should_bold_h2() -> Bool {
        return false
    }
    

    func fetchPrice() -> Double {
        return 0.0
    }
    
    func fetchNumView() -> Int {
        return 0
    }
    
}


// Objects representing a user within MessengerKit
/*// Must conform to this protocol.
extension User: MSGUser {
    
    // protocol with MSGUser
    var displayName: String {
        get { return self.name ?? "" }
    }

    /// The avatar for the user.
    /// This is optional as an `avatarUrl` can be provided instead.
    var avatar: UIImage? {
        get { return nil }
        set { return }
    }
    
    /// The URL for an avatar.
    /// This is optional as an `avatar` can be provided instead.
    var avatarUrl: URL? {
        get { return self.fetchThumbURL() }
        set { return }
        
    }
    
    /// Whether this user is the one sending messages.
    /// This is used to determine which bubble is rendered.
    var isSender: Bool {
        get { return self.uuid == UserAuthed.shared.uuid }
    }
    
    var msgUser_uuid : String {
        get { return self.uuid }
    }    
}
*/
