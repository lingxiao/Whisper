//
//  NewCohortView.swift
//  byte
//
//  Created by Xiao Ling on 1/29/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//



import Foundation
import UIKit
import SwiftEntryKit
import Player

//MARK:- protocol + constants

protocol NewCohortViewDelegate {
    func onDismissNewCard( from card: NewCohortView ) -> Void
    func onCreateNewCard( from card: NewCohortView, image: UIImage?, name: String, isHidden: Bool ) -> Void
    func onCreateEmphRoom( from org: OrgModel?, name: String ) -> Void
}

private let TOP = "Tap here to enter channel name, tap the square to pick a channel mascot. One-time channels do not require a name and will be removed once it shuts down."


//MARK:- class

class NewCohortView: UIViewController {

    var optParent: UIView?
    var h1: UITextView?
    var activeImg: UIImageView?
    
    // picked media
    var org: OrgModel?
    var club: Club?
    let imagePicker = UIImagePickerController()
    var newlyPickedImage: UIImage?
    
    var delegate: NewCohortViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func config( with org: OrgModel?, club: Club? = nil ){
        self.org = org
        primaryGradient(on:self.view)
        addGestureResponders()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        layout(org)
    }
    
    public func dismissKeyboard(){
        h1?.resignFirstResponder()
    }
    
    //MARK:- responder
    
    @objc func handleDismiss(_ button: TinderButton ){
        dismissKeyboard()
        delegate?.onDismissNewCard(from: self)
    }
    
    @objc func handleHidden(_ button: TinderTextButton){
        dismissKeyboard()
        guard let h1 = self.h1 else {
            return _handleDismiss()
        }
        if h1.text == "" || h1.text == TOP {
            ToastSuccess(title: "Please enter name", body: "")
        } else {
            delegate?.onCreateNewCard(from: self, image: self.activeImg?.image, name: self.h1?.text ?? "", isHidden: true)
        }
        /*else  if let _ = self.newlyPickedImage {
            delegate?.onCreateNewCard(from: self, image: self.activeImg?.image, name: self.h1?.text ?? "", isHidden: true)
        } else {
            ToastSuccess(title: "Please select one image", body: "")
        }*/
    }

    @objc func handleVisible(_ button: TinderTextButton){
        dismissKeyboard()
        guard let h1 = self.h1 else {
            return _handleDismiss()
        }
        if h1.text == "" || h1.text == TOP {
            ToastSuccess(title: "Please enter name", body: "")
        } else {
            delegate?.onCreateNewCard(from: self, image: self.activeImg?.image, name: self.h1?.text ?? "", isHidden: false)
        }
    }
    
    @objc func handleTemp(_ button: TinderTextButton){
        dismissKeyboard()
        var str = ""
        if let xs = h1?.text {
            if xs != TOP {
                str = xs
            }
        }
        delegate?.onCreateEmphRoom(from: self.org, name: str)
    }


    @objc func onHandleTapImage(sender : UITapGestureRecognizer){
        showImagePicker()
    }
    
    //MARK:- view
    
    static func Height() -> CGFloat {
        let ht1 = AppFontSize.H3
        let ht2 = CGFloat(50)
        let R  : CGFloat = 80.0
        var dy : CGFloat = 20
        dy += ht1 + 15
        dy += R + 10
        dy += ht2*2 + 20
        return dy
    }
    
    
    private func layout(_ org: OrgModel?){
        
        let f = view.frame
        let ht1 = AppFontSize.H3
        let ht2 = CGFloat(50)
        let R  : CGFloat = 80.0
        var dy : CGFloat = 20
        var dx : CGFloat = 20

        let v = UIView(frame: CGRect(x: 0, y: 0, width: f.width, height: f.height))
        view.addSubview(v)
        self.optParent = v

        let title = VerticalAlignLabel()
        title.frame = CGRect(x: dx, y: dy, width: f.width-dx-dx, height: ht1)
        title.textAlignment = .left
        title.lineBreakMode = .byTruncatingTail
        title.verticalAlignment = .bottom
        title.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        title.textColor = Color.primary_dark
        title.backgroundColor = UIColor.clear
        title.text = "Create new channel"
        v.addSubview(title)

        dy += ht1 + 15

        let p = UIImageView(frame: CGRect(x: dx, y: dy, width: R, height: R))
        let _ = p.corner(with:R/8)
        //let _ = p.border(width: 1.0, color: Color.white.cgColor)
        p.isUserInteractionEnabled = true
        p.backgroundColor = Color.grayTertiary
        let g1 = UITapGestureRecognizer(target: self, action:  #selector(onHandleTapImage))
        p.addGestureRecognizer(g1)
        v.addSubview(p)
        self.activeImg = p
        
        dx += R + 5
        
        let h1 = UITextView(frame: CGRect(x: dx, y: dy, width: f.width-dx-10, height: R))
        h1.font = UIFont(name: FontName.light, size: AppFontSize.footerBold)
        h1.textColor = Color.grayPrimary
        h1.textAlignment = .left
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.backgroundColor = UIColor.clear
        h1.text = TOP
        h1.delegate = self
        self.h1 = h1
        v.addSubview(h1)

        dy += R + 25

        dx = (f.width - 3*15 - 4*ht2)/2
        let bC = mkBtn(dx: dx, dy: dy, R: ht2, h1: "hidden-false", h2: "Visible", color:Color.greenDark, on: v)
        bC.addTarget(self, action: #selector(handleVisible), for: .touchUpInside)

        dx += 15 + ht2
        let bL = mkBtn(dx: dx, dy: dy, R: ht2, h1: "hidden", h2: "Hidden", color:Color.redDark, on: v)
        bL.addTarget(self, action: #selector(handleHidden), for: .touchUpInside)

        dx += 15 + ht2
        let bR = mkBtn(dx: dx, dy: dy, R: ht2, h1: "timer-2", h2: "One-time", color:Color.purpleLite, on: v)
        bR.addTarget(self, action: #selector(handleTemp), for: .touchUpInside)

        dx += 15 + ht2
        let bE = mkBtn(dx: dx, dy: dy, R: ht2, h1: "pass", h2: "Cancel", color:Color.grayQuaternary, on: v)
        bE.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)

    }

    private func mkBtn( dx: CGFloat, dy: CGFloat, R: CGFloat, h1 : String, h2: String, color:UIColor, on v: UIView ) -> TinderButton {
        
        let bA = TinderButton()
        bA.frame = CGRect(x: dx, y: dy, width: R, height: R)
        bA.changeImage(to: h1, alpha: 1.0, scale: h1 == "pass" ? 0.55 : 0.40, color: UIColor.white)
        bA.backgroundColor = color
        v.addSubview(bA)
        
        let tv = mkText(with: h2, dy: dy + R + 2, big: false )
        v.addSubview(tv)
        tv.center.x = bA.center.x
        
        return bA
    }
    
    private func mkText( with str: String, dy: CGFloat, big: Bool ) -> UITextView {
            
        let f = self.view.frame
        let font = big
            ?  UIFont(name: FontName.bold, size: AppFontSize.H2)
            :  UIFont(name: FontName.light, size: AppFontSize.footer)

        let tht = big ? AppFontSize.H3 + 20 : AppFontSize.footer + 10

        let h1 = UITextView(frame: CGRect(x: 0, y: dy, width: f.width, height: tht))
        h1.text = str
        h1.textAlignment = .center
        h1.font = font
        h1.backgroundColor = UIColor.clear
        h1.textColor = Color.grayPrimary
        h1.isUserInteractionEnabled = false
        return h1
    }
    

}


//MARK:- delegate image picker


extension NewCohortView: UIImagePickerControllerDelegate,UINavigationControllerDelegate  {

    func showImagePicker(){
        permitAVCapture(){(succ,msg) in
            if ( succ ){
                self.openImagePicker()
            } else {
                return ToastSuccess(title: "", body: "We do not have permission to open your camera roll")
            }
        }
    }
    
    func showVideoPicker(){
        permitAVCapture(){(succ,msg) in
            if ( succ ){
                self.openVideoPicker()
            } else {
                return ToastSuccess(title: "", body: "We do not have permission to open your files")
            }
        }
    }

    //@use: open picker for file only
    func openImagePicker(){
        DispatchQueue.main.async {
            self.imagePicker.allowsEditing = true
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }
    }

    //@use: open picker for file only
    func openVideoPicker(){
    }
    
    
    // @use: reset image in the view, *then* save to db
    func imagePickerController(
         _ picker: UIImagePickerController
        , didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {

        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.newlyPickedImage = pickedImage
            self.activeImg?.image = pickedImage
        } else if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.newlyPickedImage = pickedImage
            self.activeImg?.image = pickedImage
        }

        self.dismiss(animated: true, completion: nil)
    }

}


//MARK:- delegate text field

extension NewCohortView : UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        SwiftEntryKit.dismiss()
        
        if textView.text == TOP {
            textView.text = ""
            textView.textColor = UIColor.black
            textView.font = UIFont(name: FontName.bold, size: AppFontSize.body2)
        }
        
    }

}

extension NewCohortView {

    func _handleDismiss(){
        dismissKeyboard()
        delegate?.onDismissNewCard(from: self)
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
            
            case .down:
                _handleDismiss()
            default:
                break
            }
        }
    }
}


