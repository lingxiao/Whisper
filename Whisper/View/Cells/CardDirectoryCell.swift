//
//  CardDirectoryCell.swift
//  byte
//
//  Created by Xiao Ling on 1/17/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView
import Player



//MARK:- protocol + type
protocol DeckCoverViewDelegate {
    func didTap(on deck: FlashCardDeck? ) -> Void
}


//MARK:- Cell-

private let textHt : CGFloat = 10 + AppFontSize.body2 + AppFontSize.footer


/*
 @Use: display user's screen
*/
class CardDirectoryCell: UITableViewCell, DeckCoverViewDelegate {

    static var identifier: String = "CardDirectoryCell"
    
    static let textHeight = textHt
    
    var parent: UIView?
    var widget: ClubWidgets?
    var delegate: DeckCoverViewDelegate?

    fileprivate var cells : [DeckCoverView] = []
    
    /*
     @use: reset all child views
     https://stackoverflow.com/questions/54188027/how-to-reset-uicollectionview-in-swift
     */
    override func prepareForReuse() {
        super.prepareForReuse()
        for c in cells {
            c.player?.stop()
            c.removeFromSuperview()
        }
        self.cells = []
        parent?.removeFromSuperview()
    }
    
    func didTap(on deck: FlashCardDeck? ){
        delegate?.didTap(on: deck)
    }

    
    func config( with decks: [FlashCardDeck] ){
        
        if decks.count == 0 { return }
        let f = self.frame
        let pv = UIView(frame: CGRect(x: 20, y: 5, width: f.width-20, height: f.height))
        pv.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 20)
        addSubview(pv)
        self.parent = pv

        //left
        var dx : CGFloat = 15
        let wd = (f.width - 2*dx - 10)/2
        let ht = f.height - 10
        
        for deck in decks {
            let v = DeckCoverView(frame: CGRect(x: dx, y: 10, width: wd, height: ht))
            v.config(with: deck)
            addSubview(v)
            v.delegate = self
            self.cells.append(v)
            dx += wd + 10
        }
        
    }
        

}


fileprivate class DeckCoverView : UIView {
    
    var deck: FlashCardDeck?
    var delegate: DeckCoverViewDelegate?
    
    var player: Player?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func config( with deck: FlashCardDeck){
        
        self.deck = deck
        let _ = self.tappable(with: #selector(onTap))
        layout()

    }
    
    
    @objc func onTap(){
        delegate?.didTap(on: self.deck)
    }
    
    private func layout(){
        
        if GLOBAL_DEMO {
            
            layoutImage(on: nil)
            
        } else {
        
            deck?.getPreview(){ card in
                
                guard let card = card else {
                    self.layoutText()
                    return
                }
                
                switch card.kind {
                case .video:
                    self.layoutVideo( on: card )
                case .image:
                    self.layoutImage( on: card )
                default:
                    self.layoutText()
                }
            }
        }

        layoutSubtitles()
    }
    
    private func layoutVideo( on card: FlashCard ){
        
        let f = self.frame

        let player = Player()
        player.muted = true
        player.view.frame = CGRect(x: 0, y: 0, width: f.width, height: f.height-textHt)
        player.view.backgroundColor = Color.blue1
        player.fillMode = .resizeAspectFill
        let _ = player.view.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 5)

        addSubview(player.view)
        self.player = player

        card.awaitMedia(){ url in
            self.player?.url = url
        }


    }
    
    private func layoutImage( on card: FlashCard? ){
        
        let f = self.frame
        let imgv = UIImageView(frame: CGRect(x: 0, y: 0, width: f.width, height: f.height-textHt))
        let _ = imgv.corner(with:5)
        imgv.backgroundColor = Color.blue1
        addSubview(imgv)
        
        if GLOBAL_DEMO {
            let name = deck?.uuid ?? ""
            let pic = UIImage(named: name)
            imgv.image = pic
        } else {
            ImageLoader.shared.injectImage(from: card?.fetchThumbURL(), to: imgv){ _ in return }
        }

    }

    
    private func layoutText(){
        
        let f = self.frame

        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: f.width, height: f.height-textHt))
        v.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 5)
        v.backgroundColor = Color.blue1
        addSubview(v)
        
        // title
        let h1 = UILabel(frame: CGRect(x: 20, y: 20, width: f.width-40, height: f.height - textHt ))
        h1.numberOfLines = 3
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.body2)
        h1.lineBreakMode = NSLineBreakMode.byWordWrapping
        h1.text = deck?.get_H1() ?? ""
        h1.isUserInteractionEnabled = false
        h1.backgroundColor = UIColor.clear
        h1.textAlignment = .left
        h1.textColor = Color.secondary_dark
        v.addSubview(h1)
        
       
    }

    private func layoutSubtitles(){
        
        let f = self.frame
        var dy = f.height - textHt

        // title
        let label = UILabel(frame: CGRect(x: 0, y: dy, width: f.width-40, height: AppFontSize.body))
        label.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
        label.lineBreakMode = .byTruncatingTail
        label.text = deck?.get_H1() ?? ""
        label.isUserInteractionEnabled = false
        label.backgroundColor = UIColor.clear
        label.textAlignment = .left
        label.textColor = Color.primary_dark
        addSubview(label)
        
        dy += 5 + AppFontSize.footer

        let h2 = UILabel(frame: CGRect(x: 0, y: dy, width: f.width, height: AppFontSize.footer))
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footerLight)
        h2.lineBreakMode = .byTruncatingTail
        h2.text = deck?.get_H2() ?? ""
        h2.backgroundColor = UIColor.clear
        h2.textColor = Color.grayPrimary
        h2.textAlignment = .left
        addSubview(h2)
    }
    


}



