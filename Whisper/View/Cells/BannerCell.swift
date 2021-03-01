//
//  BannerCell.swift
//  byte
//
//  Created by Xiao Ling on 2/21/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//


import Foundation
import UIKit


//MARK:- banner cell-

class BannerCell: UITableViewCell {
    
    static let identifier = "BannerCell"

    // view
    var parent: UIView?
    var h1: UITextView?
    var h2: UITextView?

    // data
    var str: String = ""
    
    override func prepareForReuse() {
        super.prepareForReuse()
        h1?.removeFromSuperview()
        h2?.removeFromSuperview()
        parent?.removeFromSuperview()
    }
        
    func config( with str: String, color bkColor: UIColor = Color.tan ){

        self.str = str

        let f = self.frame

        // container view
        let parent = UIView(frame:CGRect(x: 20, y: 0, width: f.width-40, height: f.height))
        parent.backgroundColor = bkColor
        addSubview(parent)
        parent.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: f.height/5)
        self.parent = parent
        
        let pf = parent.frame
        
        let h1 = UITextView(frame:CGRect(x:10,y:0,width:pf.width-20,height:pf.height/2-2))
        h1.textAlignment = .center
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.body2)
        h1.backgroundColor = bkColor
        h1.textColor = Color.white
        h1.text = "Welcome"
        h1.isUserInteractionEnabled = false
        parent.addSubview(h1)
        self.h1 = h1
        
        // h2
        let h2 = UITextView(frame:CGRect(x:10,y:pf.height/2-2,width:pf.width-20,height:pf.height/2))
        h2.textAlignment = .center
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.font = UIFont(name: FontName.icon, size: AppFontSize.body2)
        h2.backgroundColor = bkColor
        h2.textColor = Color.white
        h2.text = str
        h2.isUserInteractionEnabled = false
        parent.addSubview(h2)
        self.h2 = h2
    }
      
}

//MARK:- hero cell-

class OnboardHeroCell: UITableViewCell {

    static let identifier = "OnboardHeroCell"

    // view
    var container: UIView?
    var img: UIImageView?
    var h1: UITextView?
    var h2: UITextView?
    var line: UIView?
    var btn: TinderButton?

    override func prepareForReuse() {
        super.prepareForReuse()
        self.img?.removeFromSuperview()
        self.h1?.removeFromSuperview()
        self.h2?.removeFromSuperview()
        self.line?.removeFromSuperview()
    }
    
    static func Height( width: CGFloat ) -> CGFloat {
        let R = width - 120
        let ht = AppFontSize.footerBold + 10
        return R + 10 + ht + 20 + ht + 5
    }
    
    func config( with url: URL?, str: String, color: UIColor = Color.white ){

        self.backgroundColor = color
        
        let f = self.frame
        let R = f.width - 120
        let ht = AppFontSize.footerBold + 10
        
        var dy = CGFloat(10)
        
        // image view
        let v = UIImageView(frame:CGRect(x:(f.width-R)/2, y:dy, width: R, height: R))
        let _ = v.corner(with: 10)
        v.backgroundColor = Color.grayTertiary
        ImageLoader.shared.injectImage( from: url, to: v ){ succ in return }
        self.addSubview(v)
        self.img = v
        
        //shawdow
        v.layer.shadowPath = UIBezierPath(rect: v.bounds).cgPath
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 1
        v.layer.shadowOffset = .zero
        v.layer.shadowRadius = 10
        
        dy += R + 10

        let h1 = UITextView(frame:CGRect(x: 10, y: dy, width: f.width-20, height: ht))
        h1.textAlignment = .center
        h1.font = UIFont(name: FontName.light, size: AppFontSize.footerBold)
        h1.textColor = Color.grayPrimary
        h1.backgroundColor = color
        h1.text = str
        h1.isUserInteractionEnabled = false
        addSubview(h1)
        
        dy += ht
        
        let h2 = UITextView(frame:CGRect(x: 10, y: dy, width: f.width-20, height: ht))
        h2.textAlignment = .center
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.font = UIFont(name: FontName.bold, size: AppFontSize.footerBold)
        h2.backgroundColor = color
        h2.textColor = Color.primary_dark
        h2.text = "Help us refine your interests"
        h2.isUserInteractionEnabled = false
        addSubview(h2)
        self.h2 = h2

    }

}


//MARK:- banner cell-

protocol TagCellDelegate {
    func didTap( on tag: TagModel? ) -> Void
}

class TagCell: UITableViewCell, TagCellDelegate {
    
    static let identifier = "TagCell"
    var delegate: TagCellDelegate?

    // view
    private var views: [OnboardTagView] = []

    // data
    var str: String = ""
    
    override func prepareForReuse() {
        super.prepareForReuse()
        for v in views {
            v.removeFromSuperview()
        }
    }

    func config( with tags: [TagModel], actives: [TagModel] ){
        
        let f = self.frame
        var dx = CGFloat(20)
        let w = (f.width - 2*dx - 15)/2
        
        for tag in tags {
            let v = OnboardTagView(frame:CGRect(x:dx,y:0,width:w,height:f.height-10))
            v.config(with:tag)
            v.delegate = self
            v.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 8)
            self.views.append(v)
            addSubview(v)
            dx += w + 15
        }
        
        setActive(for: actives)
    }
    
    func didTap(on tag: TagModel?) {
        delegate?.didTap(on:tag)
    }
    
    private func setActive( for tags: [TagModel]){
        let ids = tags.map{ $0.uuid }
        for v in self.views {
            if let t = v.tagModel {
                v.setActive(to: ids.contains(t.uuid))
            }
        }
    }
}


private class OnboardTagView : UIView {
    
    var delegate: TagCellDelegate?
    var tagModel: TagModel?
    var h1: VerticalAlignLabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc func didTap(_ sender: UITapGestureRecognizer? = nil) {
        func fn(){ self.alpha = 0.50 }
        func gn(){ self.alpha = 1.0 }
        runAnimation( with: fn, for: 0.15 ){
            runAnimation( with: gn, for: 0.15 ){ return }
        }
        delegate?.didTap(on:self.tagModel)
    }
    
    func setActive( to b: Bool ){
        let base = getBkColor(self.tagModel)
        if b {
            self.backgroundColor = base.darker(by: 25)
            self.h1?.backgroundColor = base.darker(by: 25)
        } else {
            self.backgroundColor = base
            self.h1?.backgroundColor = base
        }
    }
    
    func config( with tag: TagModel ){
        
        self.tagModel = tag
        let color = getBkColor(tag)
        self.backgroundColor = color
        
        let f = self.frame
        let h1 = VerticalAlignLabel()
        h1.frame = CGRect(x: 10, y: 0, width: f.width-20, height: f.height)
        h1.verticalAlignment = .middle
        h1.textAlignment = .center
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.body2)
        h1.textColor = Color.primary_dark
        h1.backgroundColor = color
        h1.text = tag.get_H1()
        addSubview(h1)
        self.h1 = h1
        
        let _ = self.tappable(with: #selector(didTap))
    }
        
    private func getBkColor(_ tag: TagModel? ) -> UIColor {
        
        var color = Color.purple2
        guard let tag = tag else { return color }

        if tag.meta.contains(.fraternity) {
            color = Color.tan2
        } else if tag.meta.contains(.sorority) {
            color = Color.redLite // .purple2
        } else if tag.meta.contains(.grad_year) {
            color = Color.grayTertiary
        } else {
            color = Color.blue1 //redLite
        }
        return color
    }

}


