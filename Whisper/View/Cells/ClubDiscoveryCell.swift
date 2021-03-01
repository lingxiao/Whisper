//
//  ClubDiscoveryCell.swift
//  byte
//
//  Created by Xiao Ling on 1/11/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


protocol ClubDiscoveryCellProtocol {
    func handleTap( on user: DeckAudience? ) -> Void
    func handleBtn( on user: DeckAudience? ) -> Void
}

class ClubDiscoveryCell: UITableViewCell {
    
    static let identifier = "ClubDiscoveryCell"
    var delegate : ClubDiscoveryCellProtocol?

    // view
    var img: UIImageView?
    var btn: TinderButton?
    var h1: VerticalAlignLabel?
    var h2: VerticalAlignLabel?
    var ho: UILabel?
    var nameFont: UIFont?

    // data
    var user: DeckAudience?
    var hasBtn: Bool = false
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.img?.removeFromSuperview()
        self.btn?.removeFromSuperview()
        self.h1?.removeFromSuperview()
        self.h2?.removeFromSuperview()
        self.ho?.removeFromSuperview()
    }
    
    func config( with user: DeckAudience?, button: Bool ){

        self.user = user
        self.hasBtn = button
        
        layoutImage( btn: button )
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
        
    }
    
    
    //MARK:- events + view
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        delegate?.handleTap(on: user)
    }
    
    @objc func handleBtn(_ button: TinderButton ){
        delegate?.handleBtn(on: user)
    }
    
    //MARK:- view

    private func layoutImage( btn: Bool ){
        
        let f = self.frame
        let R = f.height - 30
        let r = f.height/2
        var dx : CGFloat = 20

        let v = UIImageView(frame:CGRect(x:dx, y:(f.height-R)/2, width: R, height: R))
        let _ = v.round()
        v.backgroundColor = Color.grayQuaternary
        
        if let url = user?.user.fetchThumbURL() {

            ImageLoader.shared.injectImage(from: url, to: v){ _ in return }

        } else {

            var char : String = ""
            if let user = user?.user {
                char = String(user.get_H1().prefix(1))
            }

            let sz = R/3
            let ho = UILabel(frame: CGRect(x: (R-sz)/2, y: (R-sz)/2, width: sz, height: sz))
            ho.font = UIFont(name: FontName.bold, size: sz)
            ho.textAlignment = .center
            ho.textColor = Color.grayQuaternary.darker(by: 50)
            ho.text = char.uppercased()
            self.ho = ho
            v.addSubview(ho)
        }

        ImageLoader.shared.injectImage( from: user?.user.fetchThumbURL(), to: v ){ succ in return }
        
        // mount
        self.addSubview(v)
        self.img = v
        
        dx += R + 15
        let wd = f.width - r - dx - 20
            
        let h1 = VerticalAlignLabel()
        h1.frame = CGRect(x: dx, y: 0, width: wd, height: f.height/2)
        h1.textAlignment = .left
        h1.verticalAlignment = .bottom
        h1.font = self.nameFont ?? UIFont(name: FontName.bold, size: AppFontSize.footerBold)
        h1.textColor = Color.primary_dark
        h1.backgroundColor = UIColor.clear
        h1.text = user?.user.get_H1() ?? ""
        
        let h2 = VerticalAlignLabel()
        h2.frame = CGRect(x: dx, y: f.height/2+2, width: wd, height: f.height/2-2)
        h2.textAlignment = .left
        h2.verticalAlignment = .top
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footer)
        h2.textColor = Color.grayPrimary
        h2.backgroundColor = UIColor.clear
        h2.text = deckAudienceIsHere(for: user) ? "Here now" : pp_deckAudienceStartTime(for: user)

        addSubview(h1)
        self.h1 = h1
        addSubview(h2)
        self.h2 = h2
        
        let btn = TinderButton()
        btn.frame = CGRect(x: 0, y:(f.height-r)/2,width:r,height:r)
        btn.changeImage(to: "dots", alpha: 1.0, scale: 1/3, color: Color.grayPrimary)
        btn.addTarget(self, action: #selector(handleBtn), for: .touchUpInside)
        btn.backgroundColor = UIColor.clear
        
        btn.center.x = f.width - r/2 - 20
        addSubview(btn)
        self.btn = btn
    }
    
}
