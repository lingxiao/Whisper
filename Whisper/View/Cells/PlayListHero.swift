//
//  PlayListHero.swift
//  byte
//
//  Created by Xiao Ling on 12/29/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


protocol PlayListHeroDelegate {
    func onSearch() -> Void
    func onPlay() -> Void
}

class PlayListHero: UITableViewCell {
    
    static let identifier = "PlayListHero"
    var delegate : PlayListHeroDelegate?

    // view
    var img: UIImageView?
    var btnL: TinderTextButton?
    var btnR: TinderTextButton?
    var line : UIView?

    // data
    var club: Club?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.img?.removeFromSuperview()
        self.btnL?.removeFromSuperview()
        self.btnR?.removeFromSuperview()
        self.line?.removeFromSuperview()
    }
    
    func config( with club: Club?, isPlaying: Bool ){
        self.club = club
        layoutImage( isPlaying )
    }

    @objc func onLeft(_ button: TinderButton ){
        delegate?.onSearch()
    }

    @objc func onRight(_ button: TinderButton ){
        delegate?.onPlay()
    }

        
    //MARK:- view
    
    private func layoutImage( _ isPlaying: Bool ){

        let f = self.frame
        let ht = AppFontSize.footerBold + 20
        let R  = f.height - ht - 50
        let r  = f.width/4

        // image
        let v = UIImageView(frame:CGRect(x:0, y:0, width: R, height: R))
        let _ = v.corner(with: 2)
        v.backgroundColor = Color.primary
        v.center.x = self.center.x
        ImageLoader.shared.injectImage( from: club?.fetchThumbURL(), to: v ){ succ in return }
        self.addSubview(v)
        self.img = v
        
        let dy = R + 30
            
        // buttonR
        let btn = TinderTextButton()
        btn.frame = CGRect(x: f.width/2 - r - 8, y: dy, width:r, height:ht)
        btn.config(with: "Add", color: Color.redDark, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
        btn.backgroundColor = Color.redLite
        btn.addTarget(self, action: #selector(onLeft), for: .touchUpInside)
        addSubview(btn)
        self.btnL = btn

        // buttonL
        let btnr = TinderTextButton()
        btnr.frame = CGRect(x:f.width/2 + 0, y: dy, width:r, height:ht)
        btnr.config(with: isPlaying ? "Pause" : "Play", color: Color.redLite, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
        btnr.backgroundColor = Color.redDark
        btnr.addTarget(self, action: #selector(onRight), for: .touchUpInside)
        addSubview(btnr)
        self.btnR = btnr
        
        // line
        let line = UIView(frame:CGRect(x: 10, y: f.height-2, width: f.width-20, height: 1))
        line.backgroundColor = Color.grayTertiary
        addSubview(line)
        self.line = line

    }
    

}


