//
//  SelectWidgetsModal.swift
//  byte
//
//  Created by Xiao Ling on 1/1/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit


private let selectCellHeight: CGFloat = 50.0

protocol SelectWidgetsModalDelegate {
    func didSelectWidgets( of widgets: [ClubWidgets] ) -> Void
}

class SelectWidgetsModal: UIView, SelectWidgetCellDelegate  {
    
    // data
    var club : Club?
    var user : User?
    var delegate: SelectWidgetsModalDelegate?
    
    //style
    let numWidgets = CGFloat(2)
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    // view
    var rows: [SelectWidgetCell] = []
    
    var selected: [Int] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    static func height() -> CGFloat {
        var dy: CGFloat = 20
        let R = selectCellHeight
        dy += AppFontSize.H3 + 30
        dy += R + 10
        dy += R + 10
        dy += AppFontSize.footerBold+30
        return dy
    }
    
    func config(  width: CGFloat, club: Club? ){
        self.width = width
        self.club = club
        layout()
    }

    // respond to tap on widget cell
    func didTapOnWidget(with code: Int){
        if selected.contains(code){
            let sm = selected.filter{ $0 != code }
            self.selected = sm
            if self.rows.count > code {
                let row = self.rows[code]
                row.setState(on: false)
            }
        } else {
            self.selected.append(code)
            if self.rows.count > code {
                let row = self.rows[code]
                row.setState(on: true)
            }
        }
    }
    
    @objc func handleTapNext(_ button: TinderTextButton ){
        var res : [ClubWidgets] = []
        for k in selected {
            let row = self.rows[k]
            if let w = row.widget{
                res.append( w )
            }
        }
        delegate?.didSelectWidgets(of: res)
        SwiftEntryKit.dismiss()
    }
    
    private func layout(){
        
        var dy: CGFloat = 10
        let R = selectCellHeight
        let w : CGFloat = self.width - 20
        
        let parent = UIView(frame: CGRect(x: 20, y: 0, width: self.width, height:  SelectWidgetsModal.height()))
        parent.roundCorners(corners: [.topLeft,.topRight, .bottomLeft, .bottomRight], radius: 15)
        parent.backgroundColor = Color.primary
        addSubview(parent)

        let v = UIView(frame:CGRect(x:0,y:0,width:width, height:20))
        v.backgroundColor = Color.primary
        parent.addSubview(v)
        
        // add header
        let h1 = UITextView(frame:CGRect(x:0,y:dy,width:width, height:AppFontSize.H3+20))
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        h1.text = "Add widgets"
        h1.textColor = Color.primary_dark
        h1.textAlignment = .center
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.backgroundColor = Color.primary
        h1.isUserInteractionEnabled = false
        parent.addSubview(h1)

        dy += AppFontSize.H3 + 30
        
        let rowA = SelectWidgetCell(frame: CGRect(x: 30, y: dy, width: w, height: R))
        rowA.config(with: "music", name: "Soundscape", code: 0, widget: ClubWidgets.music)
        addSubview(rowA)
        rowA.delegate = self
        self.rows.append(rowA)
        
        dy += R + 10
        
        let rowB = SelectWidgetCell(frame: CGRect(x: 30, y: dy, width: w, height: R))
        rowB.config(with: "flashcards", name: "Flashcards", code: 1, widget: ClubWidgets.flashCards)
        addSubview(rowB)
        rowB.delegate = self
        self.rows.append(rowB)
        
        dy += R + 10

        let vb = UIView(frame:CGRect(x:0,y:dy,width:width, height:AppFontSize.footerBold+20))
        vb.backgroundColor = Color.primary
        parent.addSubview(vb)
        
        let btn = TinderTextButton()
        btn.frame = CGRect(x: 20, y: 0, width: width-40, height: AppFontSize.footerBold+30)
        btn.config(with: "Add", color: Color.primary_dark, font: UIFont(name: FontName.bold, size: AppFontSize.body2))
//        btn.addTarget(self, action: #selector(handleTapNext), for: .touchUpInside)
        vb.addSubview(btn)
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapNext)))

        guard let club = self.club else { return }
        for wi in club.widgets {
            var idx : Int = 0
            switch wi {
            case .music:
                idx = 0
            case .flashCards:
                idx = 1
            default:
                idx = 1000
            }
            self.didTapOnWidget(with: idx)
        }
    }

}


//MARK:- cell-


protocol SelectWidgetCellDelegate {
    func didTapOnWidget( with code: Int ) -> Void
}

class SelectWidgetCell: UIView {
    
    var delegate: SelectWidgetCellDelegate?
    
    // view
    var container: UIView?
    var img: UIImageView?
    var h1: VerticalAlignLabel?
    var dot: UIImageView?

    // data
    var code: Int = 0
    var widget: ClubWidgets?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func config( with icon: String, name: String, code: Int, widget: ClubWidgets? ){
        self.code = code
        self.widget = widget
        self.backgroundColor = Color.primary
        layout( icon, name )
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
    }
    
    
    //MARK:- events + view
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        delegate?.didTapOnWidget(with:self.code)
    }
    
    func setState( on: Bool ){
        if on {
            if let pic = UIImage(named: "circle-filled"){
                let cpic = pic.imageWithColor(Color.grayPrimary)
                dot?.image = cpic
            }
        } else {
            if let pic = UIImage(named: "circle-unpicked"){
                let cpic = pic.imageWithColor(Color.grayPrimary)
                dot?.image = cpic
            }
        }
    }

    
    //MARK:- view

    private func layout( _ icon: String, _ name: String ){
        
        let f = self.frame
        let R = f.height - 30
        let dx = R + 35
        let wd = f.width - dx - 15 - R - 20

        // container view
        let parent = UIView(frame:CGRect(x: 10, y: 0, width: f.width-20, height: f.height))
        parent.backgroundColor = Color.graySecondary
        addSubview(parent)
        parent.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: f.height/6)
        self.container = parent
        
        // image view
        let v = UIImageView(frame:CGRect(x:20, y:(f.height-R)/2, width: R, height: R))
        let _ = v.corner(with: R/8)
        v.backgroundColor = Color.primary
        if let pic = UIImage(named: icon){
            let cpic = pic.imageWithColor(Color.grayPrimary)
            v.image = cpic
        }
        parent.addSubview(v)
        self.img = v
        
        // name
        let h1 = VerticalAlignLabel()
        h1.frame = CGRect(x: dx, y: 0, width: wd, height: f.height)
        h1.textAlignment = .left
        h1.verticalAlignment = .middle
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.footerBold)
        h1.textColor = Color.secondary_dark
        h1.backgroundColor = UIColor.clear
        h1.text = name
        parent.addSubview(h1)
        self.h1 = h1
        
        // select modal
        let dot = UIImageView(frame:CGRect(x:dx+wd, y:(f.height-R)/2, width: R, height: R))
        dot.backgroundColor = UIColor.clear
        if let pic = UIImage(named: "circle-unpicked"){
            let cpic = pic.imageWithColor(Color.grayPrimary)
            dot.image = cpic
        }
        parent.addSubview(dot)
        self.dot = dot


        let _ = self.tappable(with: #selector(handleTap))
    }
    
}

