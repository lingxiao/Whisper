//
//  FinishOnboardController.swift
//  byte
//
//  Created by Xiao Ling on 12/10/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit


private let NAME_PH = "First and last"

class FinishOnboardController: UIViewController, NumberPadControllerDelegateOnboard {
    
    var headerHeight: CGFloat = 80
    var textHt: CGFloat = 40
    var statusHeight: CGFloat = 20
    
    // views
    var img    : UIImageView?
    var name   : UITextField?
    var bio    : UITextView?
    
    //image
    let imagePicker = UIImagePickerController()
    var newlyPickedImage: UIImage?
    var add_sign: UILabel?

    override func viewDidLoad() {
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
        super.viewDidLoad()
        view.backgroundColor = Color.primary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        placeNavHeader()
        populate()
    }
    
    func config(){ return }
    
    @objc func handleTapImage(_ sender: UITapGestureRecognizer? = nil) {
        showImagePicker()
    }
    
    @objc func handleGoBack(_ button: TinderButton ){
        let vc = NumberPadController()
        vc.view.frame = UIScreen.main.bounds
        vc.config(with: "Enter referral code", showHeader: true, isHome: true)
        vc.onboardDelegate = self
        view.addSubview(vc.view)
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
    }
    
    /*
     @use: after syncing with sponsor, either go to home page or to additional onboarding steps
     */
    func onDidSyncWithSponsor( at code: String, with club: Club? ){

        let name = club?.getOrg()?.get_H1() ?? "the server"
        ToastSuccess(title: "Confirmed with \(name)", body: "Give us a few seconds while we sync with the server")
            
        // have onboarded,do not do it again
        AuthDelegate.shared.doNotOnboard()
        
        // wait for db to sync, then determine if additional onboarding steps needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
            SwiftEntryKit.dismiss()
            if let org = club?.getOrg() {
                if org.bespokeOnboard && ClubList.shared.fetchTags(for: org).count > 0 {
                    let vc = OnboardCommunController()
                    vc.view.frame = UIScreen.main.bounds
                    vc.config(with:club)
                    AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    AuthDelegate.shared.home?.navigationController?.popToRootViewController(animated: true)
                }
            } else {
                AuthDelegate.shared.home?.navigationController?.popToRootViewController(animated: true)
            }
        }

    }
}

//MARK:- modal specific logic to save data

extension FinishOnboardController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {        
        UserAuthed.shared.setName(textField.text)
        textField.resignFirstResponder()
        return true
    }
}



//MARK:- view

extension FinishOnboardController {
    
    func populate(){
        
        let f = view.frame

        let rect = CGRect(x: 30, y: 30, width: f.width-60, height: AppFontSize.H2 + 20)
        let font = UIFont(name: FontName.bold, size: AppFontSize.H2)!

        let h1 = appTextField(placeholder: NAME_PH, font: font, frame: rect, color: UIColor.black, placeHolderColor: Color.grayPrimary)
        h1.text = ""
        h1.textAlignment = .center
        h1.delegate = self
        h1.becomeFirstResponder()

        h1.center = self.view.center
        view.addSubview(h1)
        
        // button
        let ht  = AppFontSize.body + 30
        let btn = TinderTextButton()
        btn.frame = CGRect(x:0, y:f.height - ht - 50 ,width:f.width/2, height:ht)
        btn.config(
            with: "Enter referral code",
            color: Color.primary_dark,
            font: UIFont(name: FontName.bold, size: AppFontSize.footerBold)
        )
        btn.addTarget(self, action: #selector(handleGoBack), for: .touchUpInside)
        view.addSubview(btn)
        btn.center.x = view.center.x
        
    }
    
    
    func placeNavHeader(){
        let f = view.frame
        let frame = CGRect( x: 0, y: statusHeight, width: f.width, height: headerHeight )
        let h = AppHeader(frame: frame)
        h.config(showSideButtons: false, left: "", right: "", title: "What is your name", mode: .light, small: true)
        h.backgroundColor = UIColor.clear
        self.view.addSubview(h)
        self.view.bringSubviewToFront(h)
    }
}

//MARK:- image picker

extension FinishOnboardController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func showImagePicker(){
        permitAVCapture(){(succ,msg) in
            if ( succ ){
                self.openImagePicker()
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


    // @use: reset image in the view, *then* save to db
    func imagePickerController(
         _ picker: UIImagePickerController
        , didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {

        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.newlyPickedImage = pickedImage
            self.add_sign?.removeFromSuperview()

        }
        else if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.newlyPickedImage = pickedImage
            self.add_sign?.removeFromSuperview()
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


