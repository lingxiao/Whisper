//
//  ContactBookCell.swift
//  byte
//
//  Created by Xiao Ling on 2/15/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit

//MARK:- protocol

protocol ContactBookCellDelegate {
    func handleTap( on user: PhoneContact? ) -> Void
}


//MARK:- cell

class ContactBookCell: UITableViewCell {

    static let identifier = "ContactBookCell"
    var delegate : ContactBookCellDelegate?

    // view
    var container: UIView?
    var img: UIImageView?
    var h1: VerticalAlignLabel?
    var line: UIView?
    var letter: UILabel?

    // data
    var user: PhoneContact?
    private var changing: Bool = false
    private var color: UIColor = Color.primary
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.img?.removeFromSuperview()
        self.letter?.removeFromSuperview()
        self.h1?.removeFromSuperview()
        self.container?.removeFromSuperview()
        self.line?.removeFromSuperview()
    }

    
    func config( with user: PhoneContact?, on color: UIColor = Color.primary ){
        self.user = user
        self.backgroundColor = Color.primary
        self.color = color
        layout()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
    }
    
    func highlight( _ b : Bool ){
        if b {
            container?.backgroundColor = self.color.darker(by: 10)
            img?.backgroundColor = Color.grayTertiary.darker(by: 10)
            h1?.backgroundColor = self.color.darker(by: 10)
            self.backgroundColor = self.color.darker(by: 10)
        } else {
            container?.backgroundColor = self.color
            img?.backgroundColor = Color.grayTertiary
            h1?.backgroundColor = self.color
            self.backgroundColor = self.color
        }
    }

    
    
    //MARK:- events + view
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        delegate?.handleTap(on: self.user)
    }

    
    //MARK:- view

    private func layout(){
        
        let f = self.frame
        let R = f.height - 20
        let dx = R + 25
        let wd = f.width - dx
        
        // container view
        let parent = UIView(frame:CGRect(x: 10, y: 0, width: f.width-20, height: f.height-2))
        parent.backgroundColor = Color.primary
        addSubview(parent)
        self.container = parent

        // image view
        let v = UIImageView(frame:CGRect(x:10, y:(f.height-R)/2, width: R, height: R))
        let _ = v.corner(with: R/4)
        v.backgroundColor = Color.grayTertiary
        parent.addSubview(v)
        self.img = v
        
        var char : String = ""
        if let user = user {
            char = String(user.get_H1().prefix(1))
        }

        let sz = R/3
        let ho = UILabel(frame: CGRect(x: (R-sz)/2, y: (R-sz)/2, width: sz, height: sz))
        ho.font = UIFont(name: FontName.bold, size: sz)
        ho.textAlignment = .center
        ho.textColor = Color.grayQuaternary.darker(by: 50)
        ho.text = char.uppercased()
        self.letter = ho
        v.addSubview(ho)

        // name of song
        let h1 = VerticalAlignLabel()
        h1.frame = CGRect(x: dx, y: 0, width: wd, height: f.height)
        h1.textAlignment = .left
        h1.verticalAlignment = .middle
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        h1.textColor = Color.primary_dark
        h1.backgroundColor = Color.primary
        h1.text = self.user?.get_H1() ?? ""

        parent.addSubview(h1)
        self.h1 = h1

        // line view
        let line = UIView(frame:CGRect(x: dx+5, y: f.height-1, width: f.width-20, height: 1))
        line.backgroundColor = Color.grayTertiary
        addSubview(line)
        self.line = line
        
        let _ = self.tappable(with: #selector(handleTap))
    }
    
}
