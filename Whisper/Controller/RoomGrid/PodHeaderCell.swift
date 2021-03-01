//
//  PodHeaderCell.swift
//  byte
//
//  Created by Xiao Ling on 12/27/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


//MARK:- protocol

protocol PodHeaderCellDelegate {
    func handleTapPodHeader( on club: Club?, from room: Room?, with pod: PodItem? ) -> Void
    func onSkipR( from pod: PodItem? ) -> Void
}

//MARK:- cell

class PodHeaderCell: UITableViewCell {

    static let identifier = "PodHeaderCell"
    var delegate : PodHeaderCellDelegate?

    // view
    var container: UIView?
    var img: UIImageView?
    var h1: VerticalAlignLabel?
    var h2: VerticalAlignLabel?
    var skip: TinderButton?

    // data
    var club: Club?
    var room: Room?
    var pod : PodItem?
    
    private var changing: Bool = false
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.img?.removeFromSuperview()
        self.h1?.removeFromSuperview()
        self.h2?.removeFromSuperview()
        self.skip?.removeFromSuperview()
        self.container?.removeFromSuperview()
    }
    
    func config( with club: Club?, room: Room?, pod: PodItem? ){

        self.club = club
        self.room = room
        self.pod  = pod

        self.backgroundColor = Color.primary

        layout()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)

    }
    
    
    //MARK:- events + view
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        delegate?.handleTapPodHeader(on: self.club, from: room, with: self.pod)
    }
    
    
    @objc func handleTapSkipL(_ button: TinderButton ){
        return
    }

    @objc func handleTapSkipR(_ button: TinderButton ){
        delegate?.onSkipR(from: self.pod)
    }

    //MARK:- view

    private func layout(){
        
        let f  = self.frame
        let R  = f.height - 20
        let dx = 10 + R + 15
        let bR = CGFloat(30)
        let wd = f.width - R - 50 - bR
        
        //responder
        let _ = self.tappable(with: #selector(handleTap))

        // container view
        let parent = UIView(frame:CGRect(x: 10, y: 0, width: f.width-20, height: f.height))
        parent.backgroundColor = UIColor.clear
        addSubview(parent)
        self.container = parent
        
        // image view
        var url: URL?
        if let surl = self.pod?.pod.imageURL {
            url = URL(string:surl)
        }
        let v = UIImageView(frame:CGRect(x:10, y:(f.height-R)/2, width: R, height: R))
        let _ = v.corner(with: 2.0)
        ImageLoader.shared.injectImage( from: url, to: v ){ succ in return }
        parent.addSubview(v)
        self.img = v
        
        // inject again after a while in case url doesn't load the first time
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
            if let img = self?.img {
                ImageLoader.shared.injectImage( from: url, to: img ){ succ in return }
            }
        }
        
        // name of pod
        let h1 = VerticalAlignLabel()
        h1.frame = CGRect(x: dx, y: 0, width: wd, height: f.height/2)
        h1.textAlignment = .left
        h1.verticalAlignment = .bottom
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.body)
        h1.textColor = Color.primary_dark
        h1.backgroundColor = UIColor.clear
        h1.text = self.pod?.pod.trackName ?? ""

        parent.addSubview(h1)
        self.h1 = h1
        
        // meta data
        let h2 = VerticalAlignLabel()
        h2.frame = CGRect(x: dx, y: f.height/2+5, width: wd, height: f.height/3-5)
        h2.textAlignment = .left
        h2.verticalAlignment = .top
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footerLight)
        h2.textColor = Color.primary_dark
        h2.backgroundColor = UIColor.clear
        h2.text = self.pod?.pod.artistName ?? ""
        parent.addSubview(h2)
        self.h2 = h2

        // btn
        if let room = self.room {
            if let mem = room.getMember(UserAuthed.shared.uuid){
                if mem.state == .podding {
                    let skip = TinderButton()
                    skip.frame = CGRect(x: f.width-bR-20, y: (f.height-bR)/2, width: bR, height: bR)
                    skip.changeImage(to: "skip-R", alpha: 1.0, scale: 2/3, color: Color.primary_dark)
                    skip.backgroundColor = Color.primary
                    addSubview(skip)
                    skip.addTarget(self, action: #selector(handleTapSkipR), for: .touchUpInside)
                    self.skip = skip
                } else {
                    self.skip?.removeFromSuperview()
                }
            } else {
                self.skip?.removeFromSuperview()
            }
        }
    }
    
}


//MARK:- view wrapper

class PodHeaderCellView : UIView {
    
    var delegate: PodHeaderCellDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func config( with club: Club? ){
        let f = self.frame
        let cell  = PodHeaderCell()
        cell.frame = CGRect(x: 0, y: 0, width: f.width, height: f.height)
        cell.selectionStyle = .none
        cell.config( with: club, room: nil, pod: nil )
        addSubview(cell)
    }
    
}
