//
//  Authed+Renderable.swift
//  byte
//
//  Created by Xiao Ling on 6/9/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit



extension UserAuthed: Renderable {

    func get_H1() -> String {
        return unsafeCastString(self.name)
    }
    
    func get_H2() -> String {
        return self.bio
    }
    
    func fetchThumbURL() -> URL? {
        return self.thumbURL
    }
    
    func fetchAdminURL() -> URL?{
        return self.adminURL
    }
    
    func match(query:String?) -> Bool {
        return false
    }
    
    func should_bold_h2() -> Bool {
        return false
    }
    
    func getInstallURL() -> URL? {
        return self.installURL
    }
    
}
