//
//  FlashCardController.swift
//  byte
//
//  Created by Xiao Ling on 1/1/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView


//MARK:- class

private let bkColor = Color.black // Color.graySecondary

/*
 @Use: renders my groups
*/
class FlashCardController: UIViewController {
        
    // delegate + parent
    var delegate: ExploreParentProtocol?
    
    // style
    let headerHeight: CGFloat = 60
    var statusHeight : CGFloat = 10.0

    // main child view
    var header: FlashCardHeader?
    var left : FlashCardLeft?
    var transitioning: Bool = false
    var audienceVC: DeckAudienceController?
    
    // modal
    var newCard: NewCardView?
    var setting: FlashCardSetting?
    var confirmTag: ConfirmTag?
    var blurView: UIView?
    var dotView: AwaitWidget?
    var newCardPreview: UIView?

    // databasource
    var deck: FlashCardDeck?
    var club: Club?
    var dataSource: [Int] = [0,1]
    
    override func viewDidLoad() {

        super.viewDidLoad()
        view.backgroundColor = bkColor

        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
    }
    
        
    /*
     @use: call this to load data
    */
    func config( with deck: FlashCardDeck?, on club: Club? ){

        self.deck = deck
        self.club = club
        layout()
        addGestureResponders()
        
        // check into deck after a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0 ) { [weak self] in
            self?.deck?.checkin(from: self?.club)
        }
    }
    
    
    func layout(){

        let f = view.frame
        var dy = statusHeight
        
        let header = FlashCardHeader(frame: CGRect(x:0,y:dy,width:f.width,height:headerHeight))
        header.delegate = self
        header.config( with: self.deck )
        header.backgroundColor = UIColor.clear
        if let club = self.club {
            header.setTag(active:club.taggedThisDeck(at: self.deck))
        }
        self.header = header
        view.addSubview(header)
        
        dy += headerHeight + 10
        let ht = f.height - computeTabBarHeight()/2 - dy
        
        let left = FlashCardLeft(frame:CGRect(x: 0, y:dy, width: f.width, height:ht))
        left.config(with: deck, on: club)
        left.delegate = self
        view.addSubview(left)
        left.backgroundColor = bkColor
        self.left = left
        
   }
}




//MARK:-  header + gesture

extension FlashCardController: FlashCardHeaderDelegate {
    
    func onHandleAddCard(){
        self.handleNewCard()
    }
    
    func onHandleTag(){
        self.handleTagDeck()
    }

    func onHandleDismiss() {
        left?.stopMedia()
        newCard?.dismissKeyboard()
        deck?.checkout(from: self.club)
        delegate?.onDismissDeck(from: self.deck)
    }

    func onSettings(){
    
        newCard?.dismissKeyboard()
        newCard?.view.removeFromSuperview()
        blurView?.removeFromSuperview()

        let f  = view.frame
        let ht = FlashCardSetting.height( for: self.deck, club: self.club )
        let dy = (f.height - ht)/2

        let v = UIView()
        v.frame = UIScreen.main.bounds
        v.backgroundColor = Color.black
        v.alpha = 0.0
        view.addSubview(v)
        let g1 = UITapGestureRecognizer(target: self, action:  #selector(onTapOnBlurView))
        v.addGestureRecognizer(g1)
        self.blurView = v

        let card = FlashCardSetting(frame:CGRect(x: 10, y: f.height, width: f.width-20, height: ht))
        card.config(with: self.deck, on: self.club)
        card.delegate = self
        card.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 25)
        view.addSubview(card)
        view.bringSubviewToFront(card)
        self.setting = card
        func fn(){
            self.setting?.frame = CGRect(x: 10, y: dy, width: f.width-20, height: ht)
            self.blurView?.alpha = 1.0
        }
        runAnimation( with: fn, for: 0.25 ){ return }
    }


    func addGestureResponders(){
        let swipeRt = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRt.direction = .down
        self.view.addGestureRecognizer(swipeRt)
    }
    
    // Swipe gesture
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {

            switch swipeGesture.direction {
            
            case .right:
                break;
            case .down:
                onHandleDismiss()
            case .left:
                break;
            case .up:
                break;
            default:
                break
            }
        }
    }
}



//MARK:- footer

/*
 
 
 /*
 let right = FlashCardRight(frame:CGRect(x: 0, y:dy, width: f.width, height: ht))
 right.config(with: deck, on:club)
 right.backgroundColor = UIColor.clear
 right.alpha = 0.0
 view.addSubview(right)
 self.right = right
 
 dy += ht + 5
 
 let footer = FlashCardFooter(frame: CGRect(x: 0, y: dy, width: f.width, height: tabHeight))
 footer.config(with: self.deck, club: self.club)
 footer.delegate = self
 view.addSubview(footer)
 self.footer = footer
  */
 
 extension FlashCardController : FlashCardFooterDelegate {

    func handleTapAdd() {
        self.handleNewCard()
    }
    
    func handleTapLeft() {
        handleSwitchTab( showLeft: true)
    }
    
    func handleTapRight() {
        handleSwitchTab( showLeft: false )
    }

    private func handleSwitchTab( showLeft: Bool ){
        
        if transitioning { return }
        self.transitioning = true
        
        if !showLeft {

            func fn(){
                self.left?.alpha  = 0.0
                self.right?.alpha = 1.0
            }
            
            runAnimation( with: fn, for: 0.25 ){
                self.transitioning = false
                self.leftShown = false
                self.footer?.setActive(left:false)
            }
            
        } else {

            func fn(){
                self.left?.alpha = 1.0
                self.right?.alpha = 0.0
            }

            runAnimation( with: fn, for: 0.25 ){
                self.transitioning = false
                self.leftShown = true
                self.footer?.setActive(left:true)
            }
        }
    }
    
    
}*/
