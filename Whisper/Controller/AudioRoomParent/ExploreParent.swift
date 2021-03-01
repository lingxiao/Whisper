//
//  ExploreParent.swift
//  byte
//
//  Created by Xiao Ling on 1/9/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit



protocol ExploreParentProtocol {
    func onHandleTapDeck(on deck: FlashCardDeck?) -> Void
    func onDismissDeck( from deck: FlashCardDeck? ) -> Void
}


class ExploreParentController: UIViewController, ExploreParentProtocol {
    
    var club: Club?
    var room: Room?
    var delegate: AudioRoomParentDelegate?

    // views
    private var parnt: CardDirectoryController?
    private var child: FlashCardController?
    private var inTransition: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func config( with club: Club?, room: Room? ){
        self.club = club
        self.room = room
        mountExplore( show: true )
    }
    
    func onHandleTapDeck( on deck: FlashCardDeck? ){

        guard let deck = deck else { return }
        if inTransition { return }
        self.inTransition = true

        child?.removeFromParent()
            
        let f = view.frame
        let vc = FlashCardController()
        vc.view.frame = CGRect(x: 0, y: f.height, width: f.width, height: f.height)
        vc.config(with: deck, on: self.club)
        vc.delegate = self
        view.addSubview(vc.view)
        self.child = vc
        
        func fn(){
            self.parnt?.view.alpha = 0.0
            self.child?.view.frame = CGRect(x: 0, y: 0, width: f.width, height: f.height)
        }
        runAnimation( with: fn, for: 0.25 ){
            self.parnt?.view.removeFromSuperview()
            self.parnt = nil
            self.delegate?.didShowFlashCardDeck()
            self.inTransition = false
        }
    }
    
    func onDismissDeck( from deck: FlashCardDeck? ){
        
        if inTransition { return }
        self.inTransition = true

        let f = view.frame
        mountExplore( show: false )
        
        func fn(){
            self.parnt?.view.alpha = 1.0
            self.child?.view.frame = CGRect(x: 0, y: f.height, width: f.width, height: f.height)
        }
        runAnimation( with: fn, for: 0.25 ){
            self.child?.removeFromParent()
            self.child = nil
            self.inTransition = false
        }
    }
    
    private func mountExplore( show: Bool ){
        let vc = CardDirectoryController()
        vc.view.frame = UIScreen.main.bounds
        vc.config(with: club, room: room)
        vc.delegate = self
        vc.view.alpha = show ? 1.0 : 0.0
        view.addSubview(vc.view)
        self.parnt = vc
    }
}
