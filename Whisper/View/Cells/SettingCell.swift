//
//  SettingCell.swift
//  byte
//
//  Created by Xiao Ling on 12/24/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


protocol SettingCellProtocol {
    func handleTapName()   -> Void
    func handleTapPhoto()  -> Void
    func handleTapNumber() -> Void
    func handleTapDelete() -> Void
    func handleTapLock()   -> Void
    func handleLeaveGroup() -> Void
}

class SettingCell: UITableViewCell {
    
    static let identifier = "SettingCell"
    var delegate : SettingCellProtocol?

    // view
    var h1: VerticalAlignLabel?
    var icon: TinderButton?

    // data
    var user: User?
    var hasBtn: Bool = false
    private var changing: Bool = false
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.icon?.removeFromSuperview()
        self.h1?.removeFromSuperview()
    }
    
    func config( with kind: EditClubCellKind, club: Club? ){
        layout( kind, club )
    }
    
    //MARK:- events + view
    
    @objc func handleTapName(_ sender: UITapGestureRecognizer? = nil) {
        heavyImpact()
        delegate?.handleTapName()
    }

    @objc func handleTapPhoto(_ sender: UITapGestureRecognizer? = nil) {
        heavyImpact()
        delegate?.handleTapPhoto()
    }

    @objc func handleTapNumber(_ sender: UITapGestureRecognizer? = nil) {
        heavyImpact()
        delegate?.handleTapNumber()
    }

    @objc func handleTapDelete(_ sender: UITapGestureRecognizer? = nil) {
        heavyImpact()
        delegate?.handleTapDelete()
    }

    @objc func handleTapLock(_ sender: UITapGestureRecognizer? = nil) {
        heavyImpact()
        delegate?.handleTapLock()
    }

    @objc func handleLeaveGroup(_ sender: UITapGestureRecognizer? = nil) {
        heavyImpact()
        delegate?.handleLeaveGroup()
    }

    //MARK:- view

    private func layout( _ kind: EditClubCellKind, _ club: Club? ){
        
        var str = "name"
        var strB = ""
        
        switch kind {
        case .editName:
            str = "name"
            strB = "Edit channel name"
            let _ = self.tappable(with: #selector(handleTapName))
        case .editPhoto:
            str = "photo-stack"
            strB = "Edit channel photo"
            let _ = self.tappable(with: #selector(handleTapPhoto))
        case .editNumber:
            str = "hashtag"
            strB = "Scramble channel number"
            let _ = self.tappable(with: #selector(handleTapNumber))
        case .deleteClub:
            str = "xmark"
            strB = "Delete channel"
            let _ = self.tappable(with: #selector(handleTapDelete))
        case .leaveClub:
            str = "exit-1"
            strB = "Leave channel"
            let _ = self.tappable(with: #selector(handleLeaveGroup))
        case .lockGroup:
            if let club = club {
                if club.locked {
                    str = "locked"
                    strB = "This channel is hidden"
                } else {
                    str = "unlock"
                    strB = "This channel is visible"
                }
            } else {
                str = "locked"
                strB = "This channel is locked"
            }
            let _ = self.tappable(with: #selector(handleTapLock))
        default:
            str = "name"
        }
        
        let f    = self.frame
        let R    = AppFontSize.footerBold + 30
        
        let icon = TinderButton()
        icon.frame = CGRect(x:15, y: 5, width: R, height:R)
        icon.changeImage( to: str )
        icon.backgroundColor = UIColor.clear
        
        let h1 = VerticalAlignLabel(frame:CGRect(x: 25+R, y: 5, width: f.width-30-R-24, height: R))
        h1.font = UIFont(name: FontName.light, size: AppFontSize.footerBold)
        h1.textColor = Color.secondary_dark
        h1.textAlignment = .left
        h1.verticalAlignment = .middle
        h1.backgroundColor = UIColor.clear
        h1.isUserInteractionEnabled = false
        h1.text = strB
        
        // mount
        addSubview(h1)
        addSubview(icon)
        
        self.h1 = h1
        self.icon = icon
        
    }
    
    
}
