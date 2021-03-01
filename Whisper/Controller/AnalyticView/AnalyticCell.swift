//
//  AnalyticCell.swift
//  byte
//
//  Created by Xiao Ling on 1/11/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


protocol AnalyticCellDelegate {
}

//MARK:- separation cell

class AnalyticSeparationCell: UITableViewCell {
    
    static let identifier = "AnalyticSeparationCell"
    var bar: UIView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.bar?.removeFromSuperview()
    }
    
    func config( color: UIColor ){
        let f = frame
        let v = UIView(frame: CGRect(x: 20+(70-30)/2, y: 2, width: 5, height: f.height-4))
        let _ = v.roundCorners(corners: [.topLeft,.bottomLeft,.bottomRight,.topRight], radius: 2)
        v.backgroundColor = color
        self.bar = v
        addSubview(v)
    }
    
}

//MARK:- analytics cell

class AnalyticCell: UITableViewCell {
    
    static let identifier = "AnalyticCell"
    var delegate : AnalyticCellDelegate?

    var log: SpeakerLog?
    
    // view
    var img: UIImageView?
    var btn: TinderButton?
    var h1: VerticalAlignLabel?
    var h2: VerticalAlignLabel?
    var ho: UILabel?
    var nameFont: UIFont?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.img?.removeFromSuperview()
        self.btn?.removeFromSuperview()
        self.h1?.removeFromSuperview()
        self.h2?.removeFromSuperview()
        self.ho?.removeFromSuperview()
    }
    
    func config( with log: SpeakerLog?){
        self.log = log
        layout()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
        
    }
    
    
    //MARK:- events + view
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
    }
    
    @objc func handleBtn(_ button: TinderButton ){

    }
    
    //MARK:- view

    private func layout(){
        
        let f = self.frame
        let R = f.height - 30
        let r = f.height/2
        var dx : CGFloat = 20

        let v = UIImageView(frame:CGRect(x:dx, y:(f.height-R)/2, width: R, height: R))
        let _ = v.corner(with: R/4)
        v.backgroundColor = Color.grayQuaternary

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
        
        let h2 = VerticalAlignLabel()
        h2.frame = CGRect(x: dx, y: f.height/2+2, width: wd, height: f.height/2-2)
        h2.textAlignment = .left
        h2.verticalAlignment = .top
        h2.font = UIFont(name: FontName.bold, size: AppFontSize.footerLight+1)
        h2.textColor = Color.grayPrimary
        h2.backgroundColor = UIColor.clear

        addSubview(h1)
        self.h1 = h1
        addSubview(h2)
        self.h2 = h2        
        
        if GLOBAL_DEMO {

            let (name,_,img) = getRandomUser()
            let pic = UIImage(named: img)
            v.image = pic
            h1.text = name
            h2.text = "Spoke for \(Int.random(in: 23..<128)) seconds"

        } else {

            h1.text = log?.user.get_H1() ?? ""
            h2.text = WhisperAnalytics.pp_log(for: log)

            if let url = log?.user.fetchThumbURL() {
                DispatchQueue.main.async {
                    ImageLoader.shared.injectImage(from: url, to: v){ _ in return }
                }
            } else {
                var char : String = ""
                if let name = log?.user.get_H1() {
                    char = String(name.prefix(1))
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
        }

    }
    
}
