//
//  FlashCardLeft.swift
//  byte
//
//  Created by Xiao Ling on 1/8/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView



//MARK:- protocol


protocol FlashCardLeftDelegate {
    func handleTagDeck() -> Void
    func handleNewCard() -> Void
    func handleTapAudience(from card: FlashCard?) -> Void
}



//MARK:- class

class FlashCardLeft: UIView {
        
    // data
    var club: Club?
    var deck: FlashCardDeck?
    
    // style
    let footerHeight: CGFloat = 70
    var isEmpty : Bool = false
    
    // view
    var empView: UITextView?
    var caption: UITextView?
    var card: FlashCardCell?
    
    var delegate: FlashCardLeftDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK:- API
    
    func config( with deck: FlashCardDeck?, on club: Club? ){
        self.deck = deck
        self.club = club
        deck?.awaitPartial( from: club )
        deck?.delegate = self
        layout()
        club?.getRootRoom()?.videoDelegate = self
    }
    
    func stopMedia(){
        self.card?.stopMedia()
        club?.getRootRoom()?.setPodding(to: false){ return }
    }
    
    private func layout(){

        var emp : Bool = true
        
        if let deck = self.deck {
            emp = deck.getCards().count == 0
        }

        if emp {
            self.isEmpty = true
            layoutEmpty()
        } else {
            self.isEmpty = false
            setCurrentCard()
        }
        
    }
    
    
    func setCurrentCard( _ card: FlashCard? = nil ){
        if let card = card {
            layoutCurrentCard(with: card)
        } else {
            deck?.getCurrentCard(){ card in
                if let card = card {
                    self.layoutCurrentCard(with: card)
                }
            }
        }
    }
    
    private func layoutCurrentCard( with current_card: FlashCard ){
        
        let f = self.frame
        let wd = f.width - 20
        //let ht = f.height - 15

        // remove previous
        self.card?.stopMedia()
        self.card?.removeFromSuperview()
        self.card = nil

        let cv = FlashCardCell(frame:CGRect(x:10,y:0,width: wd, height:f.height))
        cv.config( with: current_card, deck: self.deck )
        cv.delegate = self
        self.addSubview(cv)
        self.card = cv
        
        club?.getRootRoom()?.setPodding(to: false){ return }
    }
    
    
    private func layoutEmpty(){

        let f = self.frame
        let ht = AppFontSize.H1 * 2 + 20
        
        let v = UITextView(frame: CGRect(x: 20, y: (f.height-ht)/2, width: f.width-40, height: ht))
        v.font = UIFont(name: FontName.light, size: AppFontSize.body2)
        v.textColor = Color.grayPrimary
        v.textAlignment = .center
        v.textContainer.lineBreakMode = .byWordWrapping
        v.backgroundColor = UIColor.clear
        v.isUserInteractionEnabled = false
        addSubview(v)
        self.empView = v

        if let deck = self.deck {
            if deck.iCanEdit() {
                v.text = "There is nothing here yet. Tap the add button to add to collection, or swipe down to dismiss."
            } else {
                v.text = "This collection is empty, swipe down to dismiss"
            }
        } else {
            v.text = "No data"
        }

    }
    
}

//MARK:- video delegate

extension FlashCardLeft : RoomVideoDelegate {

    func didExitPodding() {
        card?.setMute(muted: true)
    }
    
    func didEnterPodding() {
        ToastSuccess(title: "", body: "Your call will be muted while the video is playing with sound")
    }    
    
}


//MARK:- flash card db responder

extension FlashCardLeft : FlashCardDeckDelegate {
    
    func didLoadNewCard(at card: FlashCard) {
        
        if self.isEmpty == false { return }
        
        func fn(){
            self.empView?.alpha = 0.0
            self.setCurrentCard()
        }
        runAnimation( with: fn, for: 0.05 ){
            self.empView?.removeFromSuperview()
            self.empView = nil
            self.isEmpty = false
            self.onTapCardRight(from:nil)
        }
    }
        
    func onSyncedNextCard( at card : FlashCard ){
        setCurrentCard( card )
    }
    
}

//MARK:- CARD responder

extension FlashCardLeft: FlashCardCellDelegate {
    
    func onTapCardRight(from card: FlashCard? ){
        self.deck?.setNext(from: self.club)
    }
    
    func onTapCardLeft(from card: FlashCard? ){
        self.deck?.setPrev(from: self.club)
    }
    
    func onHandleTapProfile( from card: FlashCard? ){
        heavyImpact()
        guard let user = card?.creator else { return }
        let vc = ProfileController()
        vc.view.frame = UIScreen.main.bounds
        vc.config( with: user, isHome: false )
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func didMute( from card: FlashCard? ){
        guard let club = club else { return }
        club.getRootRoom()?.setPodding(to: false){ return }
        AgoraClient.shared.mute()
    }

    
    func didUnmute( from card: FlashCard? ){
        club?.getRootRoom()?.setPodding(to: true){ return }
        AgoraClient.shared.mute()
    }
    
    // @use: delete flashcard from the club
    func onDelete( this card: FlashCardCell ){

        guard let data = card.card else { return }

        let title = "Are you sure you want to remove this item"
        let optionMenu = UIAlertController(title: title, message: "", preferredStyle: .actionSheet)

        let deleteAction = UIAlertAction(title: "Yes", style: .default, handler: {e in
            self.deck?.pop( data )
            self.deck?.setNext( from: self.club )
        })

        let cancelAction = UIAlertAction(title: "Cancel" , style: .cancel )

        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        AuthDelegate.shared.home?.present(optionMenu, animated: true, completion: nil)
        
    }
    
    func didTapSeeAudience( from card: FlashCard? ){
        delegate?.handleTapAudience(from: card)
    }
    
}
