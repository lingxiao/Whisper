//
//  FlashCardController+Events.swift
//  byte
//
//  Created by Xiao Ling on 1/9/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView


//MARK:- blurview responder

extension FlashCardController {
    
    @objc func onTapOnBlurView(sender : UITapGestureRecognizer){
        hideSettings()
        onDismissConfirmTag()
    }

    @objc func onTapOnBlurViewFromTag(sender : UITapGestureRecognizer){
        onDismissConfirmTag()
    }
    
}

//MARK:- left delegate

extension FlashCardController : FlashCardLeftDelegate {
    
    func handleTagDeck() {

        confirmTag?.removeFromSuperview()
        
        guard let club = club else { return }
        guard let deck = deck else { return }
        
        if club.taggedThisDeck(at: self.deck) {

            if club.iamAdmin() {
                club.untagDeck( at: deck )
                self.header?.setTag(active: false)
            } else {
                ToastSuccess(title: "Oh no!", body: "Only admins can untag collections")
            }
            
        } else {
            
            if deck.isMine() {
                
                onConfirmTag()
                
            } else {
            
                let f  = view.frame
                let ht = ConfirmTag.height()
                let dy = (f.height - ht)/2
                
                let v = UIView()
                v.frame = UIScreen.main.bounds
                v.backgroundColor = Color.black
                let _ = v.blurDark()
                v.alpha = 0.0
                view.addSubview(v)
                let g1 = UITapGestureRecognizer(target: self, action:  #selector(onTapOnBlurViewFromTag))
                v.addGestureRecognizer(g1)
                self.blurView = v

                let card = ConfirmTag(frame:CGRect(x: 10, y: f.height, width: f.width-20, height: ht))
                card.config(with: self.deck, on: self.club)
                card.delegate = self
                card.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 25)

                view.addSubview(card)
                view.bringSubviewToFront(card)
                self.confirmTag = card

                func fn(){
                    self.confirmTag?.frame = CGRect(x: 10, y: dy, width: f.width-20, height: ht)
                    self.blurView?.alpha = 1.0
                }
                runAnimation( with: fn, for: 0.25 ){ return }
            }
        }
    }
        
    func handleNewCard() {
        
        newCard?.view.removeFromSuperview()

        let f  = view.frame
        let dy = statusHeight + headerHeight + 25
        let ht = f.height - dy - f.height*0.45
        
        let v = UIView()
        v.frame = UIScreen.main.bounds
        v.backgroundColor = Color.black
        v.alpha = 0.0
        view.addSubview(v)
        self.blurView = v

        let card = NewCardView()
        card.view.frame = CGRect(x: 10, y: f.height, width: f.width-20, height: ht)
        card.config(with: self.deck)
        card.delegate = self
        card.view.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 25)
        view.addSubview(card.view)
        view.bringSubviewToFront(card.view)
        self.newCard = card
        func fn(){
            self.newCard?.view.frame = CGRect(x: 10, y: dy, width: f.width-20, height: ht)
            self.blurView?.alpha = 1.0
        }
        runAnimation( with: fn, for: 0.25 ){ return }        
    }
    
    
    func handleTapAudience(from card: FlashCard?) {
        
        if transitioning { return }

        self.transitioning = true
        let f = view.frame
        let dy = statusHeight + headerHeight

        let v = UIView()
        v.frame = UIScreen.main.bounds
        v.backgroundColor = Color.black
        v.alpha = 0.0
        view.addSubview(v)
        self.blurView = v
        
        let vc = DeckAudienceController()
        vc.view.frame = CGRect(x: 0, y: f.height, width: f.width, height: f.height-dy)
        vc.config(with: deck, on:club, isModal: true)
        vc.delegate = self
        vc.view.roundCorners(corners: [.topLeft,.topRight], radius: 15)
        view.addSubview(vc.view)
        view.bringSubviewToFront(vc.view)
        self.audienceVC = vc        
        
        func fn(){
            self.audienceVC?.view.frame = CGRect(x: 0, y: dy, width: f.width, height: f.height-dy)
            self.blurView?.alpha = 1.0
            self.transitioning = false
        }
        runAnimation( with: fn, for: 0.25 ){ return }

    }
    
}

extension FlashCardController : DeckAudienceControllerDelegate {
    
    func onDismiss(this deck: DeckAudienceController) {
        self.transitioning = true
        let f = view.frame
        let dy = statusHeight + headerHeight
        func fn(){
            self.audienceVC?.view.frame = CGRect(x: 0, y: f.height, width: f.width, height: f.height-dy)
            self.blurView?.alpha = 0.0
            self.transitioning = false
        }
        runAnimation( with: fn, for: 0.25 ){
            self.audienceVC?.view.removeFromSuperview()
            self.audienceVC = nil
            self.blurView?.removeFromSuperview()
            self.blurView = nil
            self.transitioning = false
        }
    }
}



//MARK:- new card modal delegate

extension FlashCardController : NewCardControllerDelegate {
    
    func onDismissNewCard( from card: NewCardView ){
        hideEditCard()
    }
    
    func onCreateNewCard( from card: NewCardView, front: String, back: String ){
        hideEditCard()
        deck?.push(front: front, back: back)
        respondToCreation()
    }
    
    
    func onCreateNewCard( from card: NewCardView, image: UIImage? ){
        hideEditCard()
        deck?.pushImage(image: image)
        respondToCreation()
    }
    
    func onCreateNewCard( from card: NewCardView, url : URL? ){
        hideEditCard()
        deck?.pushVideo(url: url)
        respondToCreation()
    }
    
    private func respondToCreation(){
        
        guard let left = left else { return }

        if left.isEmpty {
            
            placeIndicator()
            ToastSuccess(title: "Added!", body: "You will see the changes in the second")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                guard let self = self else { return }
                self.hideIndicator()
                self.left?.setCurrentCard( self.deck?.getLatestCard() )
            }
            
        } else {

            ToastSuccess(title: "Added!", body: "Your card will appear at the end of the collection")
            
            self.newCardPreview?.removeFromSuperview()
            self.newCardPreview = nil
            
            let f = view.frame
            let wd = f.width/5
            let ht = wd*3/2
            let dy = 2*headerHeight + statusHeight

            let v = FlashCardCell(frame: CGRect(x: f.width - wd - 20, y: dy, width: wd, height: ht))
            v.alpha = 0.0
            v.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 5)
            self.newCardPreview = v
            
            placeIndicator()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                self?.hideIndicator()
                guard let self = self else { return }
                guard let card = self.deck?.getLatestCard() else { return }
                v.config(with: card, deck: self.deck, showBtns: false)
                self.view.addSubview(v)
                self.view.bringSubviewToFront(v)

                func fn(){ self.newCardPreview?.alpha = 1.0 }
                runAnimation( with: fn, for: 0.25 ){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                        guard let self = self else { return }
                        func fn(){ self.newCardPreview?.frame = CGRect(x: f.width, y: dy, width: wd, height: ht) }
                        runAnimation( with: fn, for: 0.25 ){
                            self.newCardPreview?.removeFromSuperview()
                            self.newCardPreview = nil
                        }
                    }
                }

            }

        }

    }


    private func hideEditCard(){
        self.newCard?.dismissKeyboard()
        let f = view.frame
        func fn(){
            self.newCard?.view.frame = CGRect(x: 10, y: f.height, width: f.width-20, height: f.height-60)
            self.blurView?.alpha = 0.0
        }
        runAnimation( with: fn, for: 0.25 ){
            self.newCard?.view.removeFromSuperview()
            self.newCard = nil
            self.blurView?.removeFromSuperview()
            self.blurView = nil
        }
    }
    

    func placeIndicator(){
        
        if self.dotView != nil { return }
            
        let f = view.frame
        let R = CGFloat(100)

        // parent view
        let pv = AwaitWidget(frame: CGRect(x: (f.width-R)/2, y: (f.height-R)/2, width: R, height: R))
        let _ = pv.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 10)
        pv.config( R: R, with: "")
        pv.backgroundColor = Color.primary_transparent_A
        view.addSubview(pv)
        self.dotView = pv

        //max duration is six seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0 ) { [weak self] in
            self?.hideIndicator()
        }
        
    }
    
    func hideIndicator(){
        dotView?.stop()
        func hide() { self.dotView?.alpha = 0.0 }
        runAnimation( with: hide, for: 0.25 ){
            self.dotView?.removeFromSuperview()
            self.dotView = nil
        }
    }
}





//MARK:- setting delegate

extension FlashCardController : FlashCardSettingDelegate {

    func onDismissSettings(){
        hideSettings()
    }
    
    func handleTapDeleteDeck(){

        hideSettings()

        heavyImpact()
        guard let deck = deck else { return }
        if deck.isMine() == false { return }

        let title = "Are you sure you want to delete this deck?"
        let optionMenu = UIAlertController(title: title, message: "", preferredStyle: .actionSheet)
            
        let deleteAction = UIAlertAction(title: "Yes", style: .default, handler: {e in
            FlashCardDeck.delete(deck: deck)
            self.onHandleDismiss()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel" , style: .cancel )
            
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)

    }
    
    func onHandleTapProfile(){
        hideSettings()
        guard let user = self.deck?.creator else { return }
        let vc = ProfileController()
        vc.view.frame = UIScreen.main.bounds
        vc.config( with: user, isHome: false )
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func handleDeckTagged(){
        /*guard let deck = deck else { return }
        let vc = UserListController()
        vc.view.frame = UIScreen.main.bounds
        vc.config(title: "Tagged by", with: deck.tagged_users)
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)*/
    }
           
    func handleTapDeckPrivacy(){

        hideSettings()
        heavyImpact()
        
        guard let deck = deck else { return }
        if deck.isMine() == false { return }
        
        let bod = "Privacy defines who can view and edit this collection"
        let optionMenu = UIAlertController(title: "Set privacy", message: bod, preferredStyle: .actionSheet)
        
        for perm in deckPrivacyOpts {

            switch perm {
            case .openView_openEdit:
                let str = "Anyone can view and edit"
                let a = UIAlertAction(title: str, style: .default, handler: {a in
                    deck.setPerm(to: perm, club: self.club)
                    ToastSuccess(title: "Privacy setting is now", body: str)
                })
                optionMenu.addAction(a)
            case .openView_groupEdit:
                let str = "Anyone can view, only this cohort can edit"
                let a = UIAlertAction(title: str, style: .default, handler: {a in
                    deck.setPerm(to: perm, club: self.club)
                    ToastSuccess(title: "Privacy setting is now", body: str)
                })
                optionMenu.addAction(a)
            case .openView_creatorEdit:
                let str = "Anyone can view, only you can edit"
                let a = UIAlertAction(title: str, style: .default, handler: {a in
                    deck.setPerm(to: perm, club: self.club)
                    ToastSuccess(title: "Privacy setting is now", body: str)
                })
                optionMenu.addAction(a)
            case .groupView_groupEdit:
                let str = "Only this cohort can view and edit"
                let a = UIAlertAction(title: str, style: .default, handler: {a in
                    deck.setPerm(to: perm, club: self.club)
                    ToastSuccess(title: "Privacy setting is now", body: str)
                })
                optionMenu.addAction(a)
            case .groupView_creatorEdit:
                let str = "Only this cohort can view, only you can edit"
                let a = UIAlertAction(title: str, style: .default, handler: {a in
                    deck.setPerm(to: perm, club: self.club)
                    ToastSuccess(title: "Privacy setting is now", body: str)
                })
                optionMenu.addAction(a)
            case .closed:
                break;
            }
        }
            
        let d = UIAlertAction(title: "Cancel", style: .cancel )
        optionMenu.addAction(d)
            
        self.present(optionMenu, animated: true, completion: nil)
        

    }
    
    private func hideSettings(){
        let f = view.frame
        func fn(){
            self.setting?.frame = CGRect(x: 10, y: f.height, width: f.width-20, height: f.height-60)
        }
        runAnimation( with: fn, for: 0.25 ){
            self.setting?.removeFromSuperview()
            self.setting = nil
            self.blurView?.removeFromSuperview()
            self.blurView = nil
        }
    }
}


//MARK:- confirm delegate

extension FlashCardController : ConfirmTagDelegate {

    func onConfirmTag() {

        guard let club = club else { return }
        
        if club.taggedThisDeck(at: self.deck) {
            if club.iamAdmin() {
                club.untagDeck( at: deck )
                self.header?.setTag(active: false)
            } else {
                ToastSuccess(title: "Oh no!", body: "Only cohort admins can untag collections")
            }
        } else {
            club.tagDeck( at: self.deck, invite: false )
            self.header?.setTag(active: true)
        }

        onDismissConfirmTag()
    }
    
    func onConfirmTagAndInvite() {

        guard let club = club else { return }
        if club.taggedThisDeck(at: self.deck) {
            if club.iamAdmin() {
                club.untagDeck( at: deck )
                self.header?.setTag(active: false)
            } else {
                ToastSuccess(title: "Oh no!", body: "Only cohort admins can untag collections")
            }
        } else {
            club.tagDeck( at: self.deck, invite: true )
            self.header?.setTag(active: true)
        }

        onDismissConfirmTag()
    }
    
    func onDismissConfirmTag() {
        let f = view.frame
        func fn(){
            self.confirmTag?.frame = CGRect(x: 10, y: f.height, width: f.width-20, height: f.height-60)
        }
        runAnimation( with: fn, for: 0.25 ){
            self.confirmTag?.removeFromSuperview()
            self.confirmTag = nil
            self.blurView?.removeFromSuperview()
            self.blurView = nil
        }
    }
    
    
    
}

