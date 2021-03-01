//
//  NewCardController.swift
//  byte
//
//  Created by Xiao Ling on 1/3/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit
import Player

//MARK:- protocol + constants

protocol NewCardControllerDelegate {
    func onDismissNewCard( from card: NewCardView ) -> Void
    func onCreateNewCard( from card: NewCardView, front: String, back: String ) -> Void
    func onCreateNewCard( from card: NewCardView, image: UIImage? ) -> Void
    func onCreateNewCard( from card: NewCardView, url : URL? ) -> Void
}

private let TOP = "Front"
private let BOT = "Back"


//MARK:- class

class NewCardView: UIViewController {
    
    var deck: FlashCardDeck?

    var headerHeight: CGFloat = 40
    var textHt: CGFloat = 40
    
    var optParent: UIView?
    var textParent: UIView?
    var imgTextParent: UIView?
    var imgParent:UIView?
    
    var h1: UITextView?
    var h2: UITextView?
    var activeImg: UIImageView?
    
    // picked media
    let imagePicker = UIImagePickerController()
    var videoPicker = UIImagePickerController()
    var newlyPickedImage: UIImage?
    var newlyPickedVideoURL: URL?
    var player : Player?
    
    
    var delegate: NewCardControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func config( with deck: FlashCardDeck? ) {
        self.deck = deck
        primaryGradient(on:self.view)
        addGestureResponders()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        videoPicker.delegate = self
        videoPicker.mediaTypes = ["public.movie"]
        videoPicker.videoQuality = .typeHigh
        layoutOptionMenu()
    }
    
    public func dismissKeyboard(){
        h1?.resignFirstResponder()
        h2?.resignFirstResponder()
    }
    
    //MARK:- responder
    
    @objc func handleDismiss(_ button: TinderButton ){
        dismissKeyboard()
        delegate?.onDismissNewCard(from: self)
    }
    
    @objc func handleCancel(_ button: TinderButton ){
        textParent?.removeFromSuperview()
        layoutOptionMenu()
    }
    
    @objc func handleCancelImageOnly(_ button: TinderButton ){
        imgParent?.removeFromSuperview()
        player?.removeFromParent()
        imgTextParent?.removeFromSuperview()
        layoutOptionMenu()
    }
    
    @objc func handleAdd(_ button: TinderButton ){
        dismissKeyboard()
        guard let h1 = h1 else {
            delegate?.onDismissNewCard(from: self)
            return
        }
        if h1.text == "" || h1.text == TOP {
            ToastSuccess(title: "Please put something on the front", body: "The back is optional")
        } else {
            var back = ""
            if let str = h2?.text {
                if str != BOT {
                    back = str
                }
            }
            delegate?.onCreateNewCard(from: self, front: h1.text, back: back )
        }
    }
    
    @objc func handleSelectText(_ button: TinderTextButton ){
        self.optParent?.removeFromSuperview()
        layoutNewText()
    }
    

    @objc func handleSelectImage(_ button: TinderButton ){
        self.optParent?.removeFromSuperview()
        let h2 = "This picture will be visible to anyone"
        let h3 = "who can access the collection"
        layoutImageOnly( h1: "Select picture", h2: h2, h3:h3, isVideo: false)
    }

    @objc func handleSelectTextImage(_ button: TinderTextButton ){
        self.optParent?.removeFromSuperview()
        let h2 = "This video will be visible to anyone"
        let h3 = "who can access the collection"
        layoutImageOnly( h1: "Select video", h2: h2, h3: h3, isVideo: true)

    }
    
    @objc func handleUploadImage(_ button: TinderTextButton){
        dismissKeyboard()
        if let _ = self.newlyPickedImage {
            delegate?.onCreateNewCard(from: self, image: self.activeImg?.image)
        } else {
            ToastSuccess(title: "Please select one image", body: "")
        }
    }

    @objc func handleUploadVideo(_ button: TinderTextButton){
        dismissKeyboard()
        if let url = self.newlyPickedVideoURL {
            delegate?.onCreateNewCard(from: self, url: url)
        } else {
            ToastSuccess(title: "Please select one video", body: "")
        }
    }
    
    @objc func onHandleTapImage(sender : UITapGestureRecognizer){
        showImagePicker()
    }
    
    @objc func onHandleTapVideo(sender : UITapGestureRecognizer){
        showVideoPicker()
    }

    
    //MARK:- view
    
    
    private func layoutOptionMenu(){
        
        let f = view.frame
        var dy : CGFloat = 10
        let tht = AppFontSize.body + 20
        
        let v = UIView(frame: CGRect(x: 0, y: 0, width: f.width, height: f.height))
        view.addSubview(v)
        self.optParent = v

        // header
        let h1 = mkText(with: "Add to collection", dy: dy, big: true)
        v.addSubview(h1)
        
        dy += AppFontSize.H2 + 20
        
        let h2 = mkText(with: "Select type", dy: dy, big: false )
        v.addSubview(h2)
        

        let R : CGFloat = 60.0
        dy = (f.height - R)/2
        
        let pad: CGFloat = 40
        var dx: CGFloat = (f.width - 3*R - 2*pad )/2
        let bL = mkBtn(dx: dx, dy: dy, R: R, h1: "text", h2: "Text", on: v)
        
        dx += R + pad
        let bC = mkBtn(dx: dx, dy: dy, R: R, h1: "gallery", h2: "Picture", on: v)

        
        dx += R + pad
        let bR = mkBtn(dx: dx, dy: dy, R: R, h1: "film", h2: "Video", on: v)

        let bk = TinderTextButton()
        bk.frame = CGRect(x: 20, y: f.height - 20 - tht, width: f.width-40, height: tht)
        bk.config(with: "Cancel", color: Color.redDark, font: UIFont(name: FontName.light, size: AppFontSize.footer))
        bk.backgroundColor = UIColor.clear
        v.addSubview(bk)
        

        // add target
        bL.addTarget(self, action: #selector(handleSelectText), for: .touchUpInside)
        bC.addTarget(self, action: #selector(handleSelectImage), for: .touchUpInside)
        bR.addTarget(self, action: #selector(handleSelectTextImage), for: .touchUpInside)
        bk.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)

    }
    
   
    
    private func layoutImageOnly( h1: String, h2: String, h3: String, isVideo: Bool ){
        
        let f = view.frame
        var dy : CGFloat = 10

        let v = UIView(frame: CGRect(x: 0, y: 0, width: f.width, height: f.height))
        view.addSubview(v)
        self.imgParent = v

        // header
        let H1 = mkText(with: h1, dy: dy, big: true)
        v.addSubview(H1)
        
        dy += AppFontSize.H2 + 20
        
        let H2 = mkText(with: h2, dy: dy, big: false )
        v.addSubview(H2)
        
        dy += AppFontSize.footer + 10
        
        let H3 = mkText(with: h3, dy: dy, big: false )
        v.addSubview(H3)
        
        dy += AppFontSize.footer + 10 + 10

        let R = f.height - dy - 35 - 10 - 15
        
        if isVideo {
            
            let player = Player()
            player.playerDelegate = self
            player.view.frame = CGRect(x: 20, y: dy, width:R*2/3, height: R)
            player.view.backgroundColor = Color.secondary
            player.fillMode = .resizeAspectFill
            let _ = player.view.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 5)

            let g1 = UITapGestureRecognizer(target: self, action:  #selector(onHandleTapVideo))
            player.view.addGestureRecognizer(g1)

            v.addSubview(player.view)
            player.view.center.x = v.center.x
            self.player = player

        } else {
            
            let img = UIImageView(frame: CGRect(x: 20, y: dy, width:R, height: R))
            let _ = img.corner(with: 10)
            img.backgroundColor = Color.secondary
            let _ = img.border(width: 1.5, color: Color.grayQuaternary.cgColor)
            img.isUserInteractionEnabled = true
            
            let g1 = UITapGestureRecognizer(target: self, action:  #selector(onHandleTapImage))
            img.addGestureRecognizer(g1)

            v.addSubview(img)
            img.center.x = v.center.x
            self.activeImg = img

        }
        
        dy += R + 15
        
        let wd = (f.width-50-20)/2

        let bk = TinderTextButton()
        bk.frame = CGRect(x: 20, y: dy, width: wd, height: 35)
        bk.config(with: "Back", color: Color.primary_dark, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
        bk.backgroundColor = UIColor.clear
        v.addSubview(bk)
            
        let b1 = TinderTextButton()
        b1.frame = CGRect(x: 25+wd+20, y: dy, width: wd, height: 35)
        b1.config(with: "Upload", color: Color.primary_dark, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
        b1.backgroundColor = Color.white
        v.addSubview(b1)
        

        // add target
        if isVideo {
            b1.addTarget(self, action: #selector(handleUploadVideo), for: .touchUpInside)
        } else {
            b1.addTarget(self, action: #selector(handleUploadImage), for: .touchUpInside)
        }
        bk.addTarget(self, action: #selector(handleCancelImageOnly), for: .touchUpInside)
    }

    
    private func layoutNewText(){

        let f = view.frame
        var dy : CGFloat = 10
        let htA = f.height/3 - 1.5 - 10
        let htB = f.height*2/3-40-1.5
        let wd = (f.width-50-20)/2
        
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: f.width, height: f.height))
        view.addSubview(parent)
        self.textParent = parent
        
        // top:
        let h1 = UITextView(frame: CGRect(x: 10, y: dy, width: f.width-20, height: htA))
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.H2)
        h1.textColor = Color.grayPrimary
        h1.textAlignment = .left
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.backgroundColor = UIColor.clear
        h1.text = TOP
        h1.delegate = self
        self.h1 = h1
        parent.addSubview(h1)
        
        dy += htA
        
        let v = UIView(frame: CGRect(x: 0, y: dy, width: f.width, height: 1.5))
        v.backgroundColor = Color.graySecondary
        parent.addSubview(v)
        
        dy += 1.5
                    
        let h2 = UITextView(frame: CGRect(x: 10, y: dy, width: f.width-20, height: htB))
        h2.font = UIFont(name: FontName.regular, size: AppFontSize.body2)
        h2.text = BOT
        h2.textColor = Color.grayPrimary
        h2.textAlignment = .left
        h2.textContainer.lineBreakMode = .byWordWrapping
        h2.backgroundColor = UIColor.clear
        h2.delegate = self
        self.h2 = h2
        parent.addSubview(h2)
        
        dy += htB
        
        let w = UIView(frame: CGRect(x: 0, y: dy, width: f.width, height: 1.5))
        w.backgroundColor = Color.graySecondary
        parent.addSubview(w)
        
        dy += 1.5
        
        let btn = TinderTextButton()
        btn.frame = CGRect(x: 25+wd+20, y: dy, width: wd, height: 35)
        btn.config(with: "Add", color: Color.primary_dark, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
        btn.backgroundColor = Color.white
        parent.addSubview(btn)
        
        let btn2 = TinderTextButton()
        btn2.frame = CGRect(x: 20, y: dy, width: wd, height: 35)
        btn2.config(with: "Back", color: Color.primary_dark, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
        btn2.backgroundColor = UIColor.clear
        parent.addSubview(btn2)
        
        btn2.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        btn.addTarget(self, action: #selector(handleAdd), for: .touchUpInside)
        
    }
    
    private func mkBtn( dx: CGFloat, dy: CGFloat, R: CGFloat, h1 : String, h2: String, on v: UIView ) -> TinderButton {
        
        let bA = TinderButton()
        bA.frame = CGRect(x: dx, y: dy, width: R, height: R)
        bA.changeImage(to: h1, alpha: 1.0, scale: 1/2, color: Color.primary_dark)
        bA.backgroundColor = Color.graySecondary
        v.addSubview(bA)
        
        let tv = mkText(with: h2, dy: dy + R + 5, big: false )
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
        h1.textColor = Color.primary_dark
        h1.isUserInteractionEnabled = false
        return h1
    }
    
}


//MARK:- delegate image picker


extension NewCardView: UIImagePickerControllerDelegate,UINavigationControllerDelegate  {

    func showImagePicker(){
        permitAVCapture(){(succ,msg) in
            if ( succ ){
                self.openImagePicker()
            } else {
                return ToastSuccess(title: "", body: "We do not have permission to open your files")
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
        DispatchQueue.main.async {
            self.imagePicker.allowsEditing = true
            self.present(self.videoPicker, animated: true, completion: nil)
        }
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

        if let url = info[.mediaURL] as? URL {
            self.newlyPickedVideoURL = url
            self.player?.url = url
            self.player?.playFromBeginning()
            self.player?.muted = true
         }

        self.dismiss(animated: true, completion: nil)
    }

}


//MARK:- Player delegate

extension NewCardView: PlayerDelegate {

    func playerReady(_ player: Player) {
        return
    }
    
    func playerPlaybackStateDidChange(_ player: Player) {
        return
    }
    
    func playerBufferingStateDidChange(_ player: Player) {
        return
    }
    
    func playerBufferTimeDidChange(_ bufferTime: Double) {
        return
    }
    
    func player(_ player: Player, didFailWithError error: Error?) {
        if let e = error?.localizedDescription as? String {
            ToastSuccess(title: "Oh no!", body: e)
        }
    }


}



//MARK:- delegate text field

extension NewCardView : UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        SwiftEntryKit.dismiss()
        
        if textView.text == TOP {
            textView.text = ""
            textView.textColor = UIColor.black
        }
        
        if textView.text == BOT {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }

}

extension NewCardView {

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

//MARK:- Depricated

/*
 
 private func layoutOptionMenuB(){

     let f = view.frame
     var dy : CGFloat = 10
     let tht = AppFontSize.body + 20
     let font = UIFont(name: FontName.bold, size: AppFontSize.footer)
     
     let v = UIView(frame: CGRect(x: 0, y: 0, width: f.width, height: f.height))
     view.addSubview(v)
     self.optParent = v

     // header
     let h1 = mkText(with: "Add flash card", dy: dy, big: true)
     v.addSubview(h1)
     
     dy += AppFontSize.H2 + 20
     
     let h2 = mkText(with: "Select type of card to add to deck", dy: dy, big: false )
     v.addSubview(h2)
     
     dy += tht + 20

     let b1 = TinderTextButton()
     b1.frame = CGRect(x: 20, y: dy, width: f.width-40, height: tht)
     b1.config(with: "Text in the front and back", color: Color.primary_dark, font: font)
     b1.backgroundColor = Color.grayQuaternary
     v.addSubview(b1)
     
     dy += tht + 20

     let b2 = TinderTextButton()
     b2.frame = CGRect(x: 20, y: dy, width: f.width-40, height: tht)
     b2.config(with: "Just a picture in the front", color: Color.primary_dark, font: font)
     b2.backgroundColor = Color.grayQuaternary
     v.addSubview(b2)

     dy += tht + 20
     
     let b3 = TinderTextButton()
     b3.frame = CGRect(x: 20, y: dy, width: f.width-40, height: tht)
     b3.config(with: "Picture in the front, text in the back", color: Color.primary_dark, font: font)
     b3.backgroundColor = Color.grayQuaternary
     v.addSubview(b3)

     dy += tht + 20
     
     let bk = TinderTextButton()
     bk.frame = CGRect(x: 20, y: f.height - 20 - tht, width: f.width-40, height: tht)
     bk.config(with: "Cancel", color: Color.redDark, font: UIFont(name: FontName.light, size: AppFontSize.footer))
     bk.backgroundColor = UIColor.clear
     v.addSubview(bk)
     
     // add target
     b1.addTarget(self, action: #selector(handleSelectText), for: .touchUpInside)
     b2.addTarget(self, action: #selector(handleSelectImage), for: .touchUpInside)
     b3.addTarget(self, action: #selector(handleSelectTextImage), for: .touchUpInside)
     bk.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)

 }

 
 */
