//
//  ChatRoom.swift
//  byte
//
//  Created by Xiao Ling on 2/2/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import SwiftEntryKit
import UIKit

protocol ChatRoomDelegate {
    func onDismiss( this vc: ChatRoom ) -> Void
}

private let TOP = "Just type\nWhile you type the words will show up for everyone in the room in real time. Since only one person can text at a time, please wait until other people are done typing before you post a question."

class ChatRoom: UIViewController {
    
    // data
    var club: Club?
    var room: Room?
    var delegate: ChatRoomDelegate?

    // style
    var textHt: CGFloat = 40
    var headerHeight: CGFloat = 70
    var statusHeight: CGFloat = 10.0
    
    var h1: UITextView?
    var blurb: UITextView?
    var btn: TinderTextButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Color.primary
        addGestureResponders()
        NotificationCenter.default.addObserver(
            self,
           selector: #selector(handle(keyboardShowNotification:)),
           name: UIResponder.keyboardDidShowNotification,
           object: nil)
        
    }
    
    
    func config( with club: Club?, at room: Room? ){
        primaryGradient(on: self.view)
        self.club = club
        self.room = room
        room?.chatDelegate = self
        layout()
        if let chat = room?.chatItem {
            if chat.text != "" {
                resetTextInput()
                h1?.text = chat.text
                if chat.user.isMe() {
                    blurb?.text = "Your previous question"
                    h1?.isUserInteractionEnabled = true
                } else {
                    blurb?.text = "Someone asked a question"
                    h1?.isUserInteractionEnabled = false
                }
            }
        }
    }
    
    @objc func handleResolved(_ button: TinderTextButton ){
        let _ = room?.putResolved()
        onHandleDismiss()
     }
     
}

//MARK:- delegates

extension ChatRoom : UITextViewDelegate, RoomChatDelegate {

    func didChangeText(to str: String, by user: User?) {
        guard let user = user else { return }
        if user.isMe() {
            if str == "" {  h1?.text = "" }
            h1?.isUserInteractionEnabled = true
        } else {
            h1?.isUserInteractionEnabled = false
            h1?.text = str
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        SwiftEntryKit.dismiss()
        if textView.text == TOP {
            resetTextInput()
        }
    }
    
    func textViewDidChange(_ textView: UITextView){
        guard let str = textView.text else { return }
        guard let room = room else { return }
        let b = room.putText(str: str)
        if !b {
            ToastSuccess(title: "Someone else is asking a question right now", body: "Please wait until this person is done")
        }
    }


}


//MARK:- view

extension ChatRoom {
    
    func resetTextInput(){
        guard let textView = h1 else { return }
        textView.text = ""
        textView.textColor = UIColor.black
        textView.font = UIFont(name: FontName.bold, size: AppFontSize.body2)
    }

    func layout(){

        let f = view.frame
        var dy = headerHeight+statusHeight
        
        // header
        let rect = CGRect(x:0,y:statusHeight,width:f.width,height:headerHeight)
        let header = AppHeader(frame: rect)
        header.config( showSideButtons: true, left: "", right: "xmark", title: "Anonymous Questions", mode: .light, small: true )
        view.addSubview(header)
        header.backgroundColor = UIColor.clear
        header.delegate = self
        
        // blurb
        let h2 = UITextView(frame:CGRect(x:20,y:dy,width:f.width-40, height:AppFontSize.footer*2))
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footer)
        h2.text = "Post questions anonymously here."
        h2.textColor = Color.grayPrimary
        h2.textAlignment = .left
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.backgroundColor = UIColor.clear
        h2.isUserInteractionEnabled = false
        view.addSubview(h2)
        self.blurb = h2
        
        dy += AppFontSize.footer*2 + 20
        let ht = (f.height - dy)/2
        
        // text input
        let h1 = UITextView(frame: CGRect(x: 20, y: dy, width: f.width-40, height: ht))
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.footerBold)
        h1.textColor = Color.grayPrimary.darker(by: 25)
        h1.textAlignment = .left
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.backgroundColor = Color.graySecondary
        h1.text = TOP
        h1.delegate = self
        h1.contentInset.left = 15
        h1.contentInset.right = 15
        h1.contentInset.top = 15
        h1.contentInset.bottom = 15
        h1.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 25)
        view.addSubview(h1)
        self.h1 = h1
        
        // resolved button
        guard let room = room else { return }
        guard let club = self.club else { return }
        guard let chat = room.chatItem else { return }
        
        if chat.user.isMe() || club.iamAdmin() {
            let w = f.width/3
            let h = AppFontSize.footer + 30
            let btn = TinderTextButton()
            btn.frame = CGRect(x:(f.width-w)/2, y:f.height - 24 - h, width:w,height:h)
            btn.config(with: "Resolved", color: Color.primary_dark, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
            btn.addTarget(self, action: #selector(handleResolved), for: .touchUpInside)
            btn.backgroundColor = Color.white
            view.addSubview(btn)
            self.btn = btn
        }

    }
    
}



// MARK:- view resonders


extension ChatRoom : AppHeaderDelegate {
    
    @objc
    private func handle(keyboardShowNotification notification: Notification) {
        if let userInfo = notification.userInfo,
            let keyboardRectangle = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let f = self.view.frame
            let kht = keyboardRectangle.height
            let dy = AppFontSize.footer*2 + 20 + statusHeight + headerHeight
            let ht = f.height - dy - kht
            let frame = CGRect(x: 20, y: dy, width: f.width-40, height: ht)
            func fn(){
                self.h1?.frame = frame
                self.btn?.center.y = f.height - kht - (AppFontSize.footer+30)/2 - 20
            }
            runAnimation( with: fn, for: 0.25 ){ return }
        }
    }
    
    func onHandleDismiss() {
        delegate?.onDismiss(this: self)
        let _ = room?.putEnter()
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

