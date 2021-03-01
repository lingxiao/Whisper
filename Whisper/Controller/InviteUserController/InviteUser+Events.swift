//
//  InviteUser+Events.swift
//  byte
//
//  Created by Xiao Ling on 11/1/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit

//MARK:- table responder

extension InviteUserController: UserRowCellProtocol, AppHeaderDelegate {

    func onHandleDismiss() {
        dismissSelf()
    }

    func handleTap(on user: User?) {

        mediumImpact()
        guard let user = user else { return }
        
        // insert or remove user from selected
        if self.selected.contains( user ) {
            let small = self.selected.filter{ $0 != user }
            self.selected = small
        } else {
            self.selected.append( user )
        }
        
        // update row
        if self.isSearching {
            if let idx = filteredDataSource.firstIndex(of: user) {
                let index = IndexPath(row: idx, section: 0)
                tableView?.reloadRows(at: [index], with: .automatic)
            }
        } else {
            if let idx = dataSource.firstIndex(of: user) {
                let index = IndexPath(row: idx, section: 0)
                tableView?.reloadRows(at: [index], with: .automatic)
            }
        }
    }
    
    func handleBtn(on user: User?) {
        return
    }

}


//MARK:- footer responder

extension InviteUserController {
    
    @objc func onPressCenterBtn(_ button: TinderButton ){

        if let delegate = self.delegate {

            let (_,_) = delegate.didSelect(users: selected)

        } else {
            let uids = selected.map{ $0.uuid }
            if uids.count > 0 {
                dismissSelf()
                ToastSuccess(title: "", body: "Sent!")
                ClubList.shared.sendPushNotification( to: uids )
            } else {
                ToastSuccess(title: "", body: "Please select at least one person")
            }
        }
    }
    
    func dismissSelf(){
        self.inputTextField?.resignFirstResponder()
        AuthDelegate.shared.home?.navigationController?.popViewController(animated: true)
    }
    
}
