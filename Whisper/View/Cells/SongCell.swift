//
//  SongCell.swift
//  byte
//
//  Created by Xiao Ling on 12/29/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//


import Foundation
import UIKit
import NVActivityIndicatorView



//MARK:- protocol

protocol SongCellDelegate {
    func handleTapSong( pod: PodItem? )
    func handleTapSetting( pod: PodItem? )
}


//MARK:- cell

class SongCell: UITableViewCell {

    static let identifier = "SongCell"
    var delegate : SongCellDelegate?

    // view
    var container: UIView?
    var img: UIImageView?
    var h1: VerticalAlignLabel?
    var waveView: NVActivityIndicatorView?
    var line: UIView?
    var btn: TinderButton?

    // data
    var pod: PodItem?
    private var changing: Bool = false
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hideIndicator()
        self.img?.removeFromSuperview()
        self.h1?.removeFromSuperview()
        self.container?.removeFromSuperview()
        self.waveView?.removeFromSuperview()
        self.line?.removeFromSuperview()
        self.btn?.removeFromSuperview()
    }

    
    func config( with pod: PodItem?, playing: Bool ){
        self.pod = pod
        self.backgroundColor = Color.primary
        layout( playing )
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
    }
    
    
    //MARK:- events + view
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        delegate?.handleTapSong( pod: self.pod )
    }

    @objc func onMore(_ button: TinderButton ){
        delegate?.handleTapSetting(pod: self.pod)
    }

    
    //MARK:- view

    private func layout( _ playing: Bool ){
        
        let f = self.frame
        let R = f.height - 20
        let dx = R + 25
        let r  = CGFloat(30)
        let wd = f.width - dx - r  - 25
        
        // container view
        let parent = UIView(frame:CGRect(x: 10, y: 0, width: f.width-20, height: f.height-2))
        parent.backgroundColor = Color.primary
        addSubview(parent)
        self.container = parent

        // image view
        let v = UIImageView(frame:CGRect(x:10, y:(f.height-R)/2, width: R, height: R))
        let _ = v.corner(with: 3)
        v.backgroundColor = Color.grayTertiary
        ImageLoader.shared.injectImage( from: pod?.pod.fetchThumbURL(), to: v ){ succ in return }
        parent.addSubview(v)
        self.img = v
                
        if playing {
            placeIndicator( on: self.img, with: R )
        }
        
        // name of song
        let h1 = VerticalAlignLabel()
        h1.frame = CGRect(x: dx, y: 0, width: wd, height: f.height)
        h1.textAlignment = .left
        h1.verticalAlignment = .middle
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.body2)
        h1.textColor = Color.primary_dark
        h1.backgroundColor = UIColor.clear
        h1.text = self.pod?.pod.trackName ?? ""

        parent.addSubview(h1)
        self.h1 = h1
        
        // setting view
        let btn = TinderButton()
        btn.frame = CGRect(x:f.width-r-24,y:(f.height-r-2)/2, width:r, height:r)
        btn.changeImage(to: "dots", alpha: 1.0, scale: 1/2, color: Color.grayPrimary)
        btn.backgroundColor = Color.primary
        btn.addTarget(self, action: #selector(onMore), for: .touchUpInside)
        parent.addSubview(btn)
        self.btn = btn
        
        // line view
        let line = UIView(frame:CGRect(x: dx+5, y: f.height-1, width: f.width-20, height: 1))
        line.backgroundColor = Color.grayTertiary
        addSubview(line)
        self.line = line
        
        let _ = self.tappable(with: #selector(handleTap))
    }
    
    
    func placeIndicator( on img: UIImageView?, with _R: CGFloat ){
        
        hideIndicator()
        guard let img = img else { return }
        
        let R     = CGFloat(15)
        let frame = CGRect( x: (_R-R)/2 , y:(_R-R)/2, width: R, height: R )
        let v = NVActivityIndicatorView(frame: frame, type: .lineScale , color: Color.grayQuaternary, padding: 0)
        img.addSubview(v)
        img.bringSubviewToFront(v)
        v.startAnimating()
        self.waveView = v
    }
    
    func hideIndicator(){
        self.waveView?.stopAnimating()
        self.waveView?.removeFromSuperview()
        self.waveView = nil
    }

}
