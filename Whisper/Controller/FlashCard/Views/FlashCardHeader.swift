//
//  FlashCardHeader.swift
//  byte
//
//  Created by Xiao Ling on 1/10/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//



import Foundation
import UIKit

protocol FlashCardHeaderDelegate {
    func onHandleTag() -> Void
    func onSettings() -> Void
    func onHandleAddCard() -> Void
}


class FlashCardHeader : UIView {
    
    var delegate: FlashCardHeaderDelegate?
    
    // view
    var addBtn: TinderButton?
    var bell: TinderButton?
    
    // scroll state
    var prevHt: CGFloat = 0
    var lastOpen: Int = now()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func config( with deck: FlashCardDeck? ){
        layout( deck )
    }
    
    func setTag(active:Bool){
        bell?.changeImage(to: active ? "bookmark-on" : "bookmark-off", alpha: 1.0, scale: 2/3, color: Color.primary )
    }
    
    @objc func onBell(_ button: TinderButton ){
        delegate?.onHandleAddCard()
    }
    
    @objc func onSettings(_ button: TinderButton ){
        delegate?.onSettings()
    }
    
    @objc func onBookmark(_ button: TinderButton ){
        delegate?.onHandleTag()
    }

    /*
     @use: place image,text, and two pills
    */
    private func layout(  _ deck: FlashCardDeck? ){

        let f = self.frame
        let R = CGFloat(30)
        let lwd = f.width - 3*R - 3*10 - 20 - 20
        
        var dx : CGFloat = 20
        
        // h1
        let h1 = VerticalAlignLabel()
        h1.frame = CGRect(x: dx, y: 0, width: lwd, height: f.height/2)
        h1.textAlignment = .left
        h1.verticalAlignment = .bottom
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        h1.textColor = Color.primary
        h1.lineBreakMode = .byTruncatingTail
        h1.backgroundColor = UIColor.clear
        h1.text = deck?.get_H1() ?? "Collection"
        
        let h2 = VerticalAlignLabel()
        h2.frame = CGRect(x: dx, y: f.height/2+2, width: lwd, height: f.height/2-2)
        h2.textAlignment = .left
        h2.verticalAlignment = .top
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footer)
        h2.textColor = Color.graySecondary
        h2.lineBreakMode = .byTruncatingTail
        h2.backgroundColor = UIColor.clear
        h2.text = deck?.creator?.get_H1() ?? ""
        
        deck?.getHomeclub(){ club in
            guard let club = club else { return }
            h2.text = club.get_H1()
        }
        
        h1.isUserInteractionEnabled = false
        h2.isUserInteractionEnabled = false
        addSubview(h1)
        addSubview(h2)
        

        dx += lwd + 10
        
        // add new card
        if let deck = deck {
            if deck.iCanEdit() {
                let add = TinderButton()
                add.frame = CGRect(x:dx,y:(f.height-R), width:R, height:R)
                add.changeImage(to: "plus", alpha: 1.0, scale: 2/3, color: Color.primary)
                add.backgroundColor = UIColor.clear
                add.addTarget(self, action: #selector(onBell), for: .touchUpInside)
                addSubview(add)
            }
        }
        
        dx += R + 10
        
        // bookmark
        let bell = TinderButton()
        bell.frame = CGRect(x:dx,y:(f.height-R), width:R, height:R)
        bell.changeImage(to: "bookmark-off", alpha: 1.0, scale: 2/3, color: Color.primary)
        bell.backgroundColor = UIColor.clear
        bell.addTarget(self, action: #selector(onBookmark), for: .touchUpInside)
        addSubview(bell)
        self.bell = bell
        
        dx += R + 10

        // settings
        let prof = TinderButton()
        prof.frame = CGRect(x:dx,y:(f.height-R), width:R, height:R)
        prof.changeImage(to: "vdots", alpha: 1.0, scale: 2/3, color: Color.primary)
        prof.backgroundColor = UIColor.clear
        prof.addTarget(self, action: #selector(onSettings), for: .touchUpInside)
        addSubview(prof)

    }
    
}
