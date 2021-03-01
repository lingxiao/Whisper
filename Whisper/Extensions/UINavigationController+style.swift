//
//  AppNavigationController.swift
//  byte
//
//  Created by Xiao Ling on 5/22/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import UIKit
import Foundation


//MARK:- defualt style

extension UINavigationController  {
    
    func defaultStyle (
          namely title: String?
        , on navigationItem: UINavigationItem
    ) {

        self.navigationBar.backgroundColor = UIColor.clear
        self.navigationBar.barTintColor = UIColor.clear
        self.addCustomBottomLine(color: UIColor.clear, height: 1.0)

        self.navigationBar.isTranslucent = true
        
        self.navigationBar.titleTextAttributes = [
             .foregroundColor: UIColor.black
            , NSAttributedString.Key.font: UIFont(name: "Helvetica-Bold", size: AppFontSize.H3)! // 24)!
        ]
        
        if ( title != nil ){
            let titleLbl = UILabel()
            titleLbl.text = title
            titleLbl.textColor = UIColor.black
            titleLbl.font = UIFont.systemFont(ofSize: CGFloat(24), weight: .bold)
            let titleView = UIStackView(arrangedSubviews: [titleLbl])
            titleView.axis = .horizontal
            navigationItem.titleView = titleView
            navigationItem.titleView?.center = self.navigationBar.center
        }

    }
    

    func colored( with color: UIColor ){
        self.navigationBar.backgroundColor = color
        self.navigationBar.barTintColor = color
        self.addCustomBottomLine(color:color, height:1.0)
    }
    
    func addTitle( _ title: String? ) -> UINavigationController {
        
        if ( title == nil ){ return self }
        
        self.navigationBar.titleTextAttributes = [
             .foregroundColor: UIColor.black
            , NSAttributedString.Key.font: UIFont(name: "Helvetica-Bold", size: 24)!
        ]
        if ( title != nil ){
            let titleLbl = UILabel()
            titleLbl.text = title
            titleLbl.textColor = UIColor.black
            titleLbl.font = UIFont.systemFont(ofSize: CGFloat(24), weight: .bold)
            let titleView = UIStackView(arrangedSubviews: [titleLbl])
            titleView.axis = .horizontal
            navigationItem.titleView = titleView
            navigationItem.titleView?.center = self.navigationBar.center
        }

        return self
    }
    
    func addShadow(){
        
        // add shadow
        self.navigationBar.layer.masksToBounds = false
        self.navigationBar.layer.shadowColor = UIColor.clear.cgColor // UIColor.systemGray3.cgColor
        self.navigationBar.layer.shadowOpacity = 0.8
        self.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.navigationBar.layer.shadowRadius = 2
    }
    
    func removeShadow(){

        self.navigationBar.layer.shadowColor = UIColor.clear.cgColor
        //self.self.navigationBar.layer.shadowOpacity = 0.8
        //self.self.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        //self.self.navigationBar.layer.shadowRadius = 2
    }


    private func addCustomBottomLine(color:UIColor,height:Double){

        //Hiding Default Line and Shadow
        navigationBar.setValue(true, forKey: "hidesShadow")

        //Creating New line
        let lineView = UIView(frame: CGRect(x: 0, y: 0, width:0, height: height))
        lineView.backgroundColor = color
        navigationBar.addSubview(lineView)

        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.widthAnchor.constraint(equalTo: navigationBar.widthAnchor).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: CGFloat(height)).isActive = true
        lineView.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor).isActive = true
        lineView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
    }
}
    
    
//MARK:- Buttons


extension UINavigationController  {

    func leftButton(
          with image : UIImage!
        , on navigationItem: UINavigationItem
    ) -> UIButton {


        let button = UIButton(type: .custom)
        button.setImage( image, for: .normal)

        let ht = min(30,self.navigationBar.frame.maxY*2/3)
        
        button.frame = CGRect(x: 0, y: 0, width: ht, height: ht)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.leftBarButtonItem = barButton
        return button
    }
    
    func rightButton(
              with image : UIImage!
            , on navigationItem: UINavigationItem
        ) -> UIButton
    {
        
        let button = UIButton(type: .custom)
        button.setImage( image, for: .normal)

        let ht = min(30,self.navigationBar.frame.maxY*2/3)

        //button.backgroundColor = UIColor.yellow

        
        button.frame = CGRect(x: 0, y: 0, width: ht, height: ht)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
        return button
    }
    
    func leftBackButton( on obj: AnyObject, with tgt: Selector ){

        let _imgl = UIImage(systemName: "arrow.left")
        let imgl  = _imgl?.imageWithColor( UIColor.clear )
        let left  = self.leftButton(with: imgl, on: obj.navigationItem)
        left.addTarget(obj , action: tgt, for: .touchUpInside)

    }
    
    func rightTrashButton( on obj: AnyObject, with tgt: Selector ){

        let _imgl = UIImage(systemName: "stop.fill")
        let img   = _imgl?.imageWithColor( UIColor.blue )

        let left  = self.rightButton(with: img, on: obj.navigationItem)
        left.addTarget(obj , action: tgt, for: .touchUpInside)

    }
}

