//
//  NewDeckViewSimple.swift
//  byte
//
//  Created by Xiao Ling on 1/17/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView


//MARK:- protocol 

protocol NewDeckViewDelegate {
    func onDismissNewDeckView() -> Void
    func onCreateNewDeck( with name: String, color: UIColor, image: UIImage? ) -> Void
}

let NDTOP = "Deck Name"

//MARK:- class-

class NewDeckViewSimple: UIViewController {

    // data + delegate
    var club : Club?
    var delegate: NewDeckViewDelegate?
    
    // main child view
    let headerHeight: CGFloat = 40
    var header: AppHeader?
    var h1: UITextView?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    static func height() -> CGFloat {
        var dy : CGFloat = 10
        dy += 40 + 25
        dy += AppFontSize.H2 + 20
        dy += AppFontSize.body2 + 20
        dy += 20
        return dy
    }
    
    /*
     @use: call this to load data
    */
    func config( from club : Club? ){

        self.club = club
        primaryGradient(on: self.view)
        addGestureResponders()
        layout()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
            self?.h1?.becomeFirstResponder()
        }
    }

    
    
    //MARK:- view
    
    func layout(){

        let f = view.frame

        // header
        let header = AppHeader(frame: CGRect(x:0,y:10, width:f.width,height:headerHeight))
        header.delegate = self
        header.config( showSideButtons: true, left: "", right: "xmark", title: "Create new collection", mode: .light, small: true )
        header.label?.textColor = Color.primary_dark
        view.addSubview(header)
        header.backgroundColor = UIColor.clear
        self.header = header

        var dy = headerHeight+25

        // fill in name
        let h1 = UITextView(frame:CGRect(x:20,y:dy,width:f.width-40,height:AppFontSize.H1+10))
        h1.textAlignment = .left
        h1.backgroundColor = UIColor.clear
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        h1.text = NDTOP
        h1.textColor = Color.grayPrimary
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.isUserInteractionEnabled = true
        h1.delegate = self
        self.h1 = h1
        view.addSubview(h1)
        
        dy += AppFontSize.H1 + 25
        
        // footer
        let w = f.width/3
        let h = AppFontSize.body2 + 20
        let b2 = TinderTextButton()
        b2.frame = CGRect(x:(f.width-w)/2,y:dy, width:w,height:h)
        b2.config(with: "Create", color: Color.primary, font: UIFont(name: FontName.bold, size: AppFontSize.footer))
        b2.addTarget(self, action: #selector(handleTapAdd), for: .touchUpInside)
        b2.backgroundColor = Color.redDark
        view.addSubview(b2)
    }
        
    // create footer
    @objc func handleTapAdd( _ button: TinderButton ){
        
        guard let str = h1?.text else {
            return ToastSuccess(title: "Oh no!", body: "An error occured")
        }
        
        if str == "" {
            ToastSuccess(title: "Please enter a name", body: "")
            self.h1?.becomeFirstResponder()
        } else {
            delegate?.onCreateNewDeck(with: str, color:Color.blue1, image:nil)
        }
    }
        

}


//MARK:- text input responder


extension NewDeckViewSimple : UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.text == NDTOP {
            textView.text = ""
            textView.textColor = UIColor.black
        }

    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            let str = textView.text
            if str == "" {
                ToastSuccess(title: "Please enter a name", body: "")
                return false
            } else {
                textView.resignFirstResponder()
                return false
            }
        }
        return true
    }
    
}




//MARK:- gesture

extension NewDeckViewSimple: AppHeaderDelegate {

    func onHandleDismiss(){
        delegate?.onDismissNewDeckView()
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
                delegate?.onDismissNewDeckView()
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




