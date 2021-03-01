//
//  ViewProtocols.swift
//  byte
//
//  Created by Xiao Ling on 5/27/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit



protocol ToggleDisplay {

    var is_hidden: Bool! { get set }
    func doHide ( _ complete: @escaping (Bool) -> Void)
    func doShow ( _ complete: @escaping (Bool) -> Void)
}



//MARK:- Protocol so model can interface directly w/ controllers

/*
 @Use: extend Object w/ this so it can be rendered in a table
 */

protocol Renderable {
    var uuid : UniqueID { get set }
    func get_H1() -> String
    func get_H2() -> String
    func fetchThumbURL() -> URL?
    func match( query: String? ) -> Bool
    func should_bold_h2() -> Bool

}


enum RenderCategory {
    case user
    case group
}


