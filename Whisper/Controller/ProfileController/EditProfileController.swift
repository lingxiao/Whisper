//
//  EditProfileController.swift
//  byte
//
//  Created by Xiao Ling on 11/10/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit
import KeyboardAvoidingView

class EditProfileController: UIViewController {
    
    var pad_top: CGFloat = 20
    var headerHeight: CGFloat = 80
    var textHt: CGFloat = 40
    var statusHeight : CGFloat = 10.0

    // views
    var kbView : KeyboardAvoidingView?
    var img    : UIImageView?
    var name   : UITextField?
    var bio    : UITextField?
    var ig     : UITextField?
    var linkedin: UITextField?
    var youtube: UITextField?
    var spotify: UITextField?
    var twitter: UITextField?
    
    //image
    let imagePicker = UIImagePickerController()
    var newlyPickedImage: UIImage?

    override func viewDidLoad() {

        super.viewDidLoad()
        primaryGradient(on:view)
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }

        addGestureResponders()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        placeNavHeader()
        
        // layout kb avoiding view
        let f = view.frame
        let dy = pad_top + headerHeight
        let keyboardAvoidingView = KeyboardAvoidingView(frame: CGRect(x:0, y:dy, width: f.width, height: f.height))
        keyboardAvoidingView.translatesAutoresizingMaskIntoConstraints = true
        keyboardAvoidingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        keyboardAvoidingView.backgroundColor = UIColor.clear
        self.kbView = keyboardAvoidingView
        view.addSubview(keyboardAvoidingView)
        
        // lay out textfields
        populate()
        
        if UserAuthed.shared.numEdits > MAX_NAME_EDITS {
            name?.isUserInteractionEnabled = false
            bio?.becomeFirstResponder()
        } else {
            name?.becomeFirstResponder()
        }
    }
    
    func config(){ return }
    
}

//MARK:- modal specific logic to save data

extension EditProfileController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        let me = UserAuthed.shared
        let str = textField.text
        
        switch textField.placeholder {

        case "Name":

            if UserAuthed.shared.numEdits > MAX_NAME_EDITS {

                ToastSuccess(title: "", body: "Your name can no longer be edited")
                bio?.becomeFirstResponder()
                
            } else {

                me.setName( str )
                bio?.becomeFirstResponder()

            }

        case "Bio":
            me.setBio( str )
            twitter?.becomeFirstResponder()

        case "Instagram":
            me.setIG(str)
            //twitter?.becomeFirstResponder()
            //linkedin?.becomeFirstResponder()

        case "Twitter":
            me.setTwitter(str)
            twitter?.resignFirstResponder()
            
        default:
            break;
        }

        return true
    }
}


//MARK:- view

extension EditProfileController {
    
    func populate(){
        
        guard let me = UserList.shared.yieldMyself() else { return }
        
        var dy = CGFloat(25) + headerHeight + statusHeight
        let R  = view.frame.width/3

        let profileImg = UIImageView(frame: CGRect(x:0,y:dy,width:R,height:R))
        let _ = profileImg.round()
        profileImg.backgroundColor = Color.grayTertiary
        profileImg.center.x = self.view.center.x
        self.view.addSubview(profileImg)
        self.img = profileImg
        profileImg.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTapImage(_:)))
        profileImg.addGestureRecognizer(tap)
        
        ImageLoader.shared.injectImage(from: me.fetchThumbURL(), to: self.img){ b in return }

        dy = dy + R/2
        
        let t1 = placeInput(logo: "name", placeHolder: "Name", val: me.get_H1(), dy: dy)
        dy = dy + textHt + 5
        self.name = t1
        
        let t2 = placeInput(logo: "text", placeHolder: "Bio", val: me.get_H2(), dy: dy)
        dy = dy + textHt + 5
        self.bio = t2
        
        let t7 = placeInput(logo: "twitter", placeHolder: "Twitter", val: me.twitter, dy: dy)
        self.twitter = t7

        /*let t3 = placeInput(logo: "instagram", placeHolder: "Instagram", val: me.instagram , dy: dy)
        dy = dy + textHt + 5
        self.ig = t3*/

        /*let t4 = placeInput(logo: "link-sq", placeHolder: "Website", val: me.website, dy: dy)
        dy = dy + textHt + 5
        self.linkedin = t4
         */
        
    }
    
    func placeInput( logo: String, placeHolder: String, val: String, dy: CGFloat ) -> UITextField {
        
        let f    = view.frame
        let R    = CGFloat(textHt)
        let font = UIFont(name: FontName.bold, size: AppFontSize.body2)!
        let rect = CGRect(x: 30+R, y: dy, width: f.width-30-R-20, height: textHt)
        
        let icon = TinderButton()
        icon.frame = CGRect(x:15, y: dy, width: R, height:R)
        icon.changeImage( to: logo )
        icon.backgroundColor = UIColor.clear

        let h1 = appTextField(
              placeholder: placeHolder
            , font: font
            , frame: rect
            , color: UIColor.black
            , placeHolderColor: Color.grayQuaternary
        )
        h1.textAlignment = .left
        h1.text = val
        h1.delegate = self
        
        // mount
        kbView?.addSubview(h1)
        kbView?.addSubview(icon)

        return h1

    }
    
    func placeNavHeader(){
        let f = view.frame
        let frame = CGRect( x: 0, y: statusHeight, width: f.width, height: headerHeight )
        let h = AppHeader(frame: frame)
        h.config( showSideButtons: true, left: "", right: "xmark", title: "Edit Profile", mode: .light )
        h.delegate = self
        h.backgroundColor = UIColor.clear
        self.view.addSubview(h)
        self.view.bringSubviewToFront(h)
    }
}

//MARK:- image picker

extension EditProfileController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func showImagePicker(){
        permitAVCapture(){(succ,msg) in
            print( succ, msg )
            if ( succ ){
                self.openImagePicker()
            } else {
                return ToastSuccess(title: "", body: "We do not have permission to open your camera roll")
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


    // @use: reset image in the view, *then* save to db
    func imagePickerController(
         _ picker: UIImagePickerController
        , didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.newlyPickedImage = pickedImage

        }
        else if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.newlyPickedImage = pickedImage
        }

        dismiss(animated: true, completion: nil)
        saveImage()
        ToastSuccess(title: "", body: "Your picture has been saved!")
    }


    // @Use: save profile image
    func saveImage(){
        guard let image = self.newlyPickedImage else {
            return ToastSuccess(title: "", body: "Network error")
        }
        self.img?.image = newlyPickedImage
        UserAuthed.shared.changeImage( to: image ){ (succ,msg) in
            if ( succ ){
                ToastSuccess(title:"", body:"Profile picture saved")
            } else {
                return ToastSuccess(title: "", body: "Network error")
            }
        }
    }

}


//MARK:- navigation responder

extension EditProfileController : AppHeaderDelegate {

    @objc func handleTapImage(_ sender: UITapGestureRecognizer? = nil) {
        showImagePicker()
    }

    
    func addGestureResponders(){
        let swipeRt = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRt.direction = .right
        self.view.addGestureRecognizer(swipeRt)
    }
    
    // Swipe gesture
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {

            switch swipeGesture.direction {
            
            case .right:
                onHandleDismiss()
            case .down:
                break;
            case .left:
                break;
            case .up:
                break;
            default:
                break
            }
        }
    }

    func onHandleDismiss() {
        AuthDelegate.shared.home?.navigationController?.popViewController(animated: true)
    }

}

