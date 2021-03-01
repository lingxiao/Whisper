//
//  IconController.swift
//  byte
//
//  Created by Xiao Ling on 6/13/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


class IconController: UIViewController {
    
    var ratio: CGFloat = 0
        
    override func viewDidLoad() {
        super.viewDidLoad()
        mountName()
    }
    
    private func mountName(){

        self.view.backgroundColor = Color.tertiary_dark // UIColor.black

        let f = view.frame
        let ht = f.width*0.40
        
        let h1 = UILabel(frame: CGRect(x: 0, y: 0, width: f.width, height: ht))
        h1.textAlignment = .center
        h1.text = APP_NAME
        h1.font = UIFont(name: FontName.icon, size: AppFontSize.H1*2 )
        h1.textColor = UIColor.white
        h1.center = view.center
        view.addSubview(h1)
        
        /*let dy = self.view.center.y + ht/2
        let v = UIView(frame: CGRect(x: 0, y: dy, width: 60, height: 10))
        v.backgroundColor = Color.tan
        let _ = v.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 5)
        view.addSubview(v)
        v.center.x = self.view.center.x
        */
    }
    
    private func mountLanding(){

        self.view.backgroundColor = UIColor.white

        let f = view.frame
        
        let h1 = UITextView(frame: CGRect(x: 0, y: 0, width: f.width, height: AppFontSize.H1+20))
        h1.textAlignment = .center
        h1.font = UIFont(name: FontName.icon, size: AppFontSize.H1)
        h1.textColor = Color.black
        h1.backgroundColor = UIColor.clear
        h1.text = APP_NAME
        h1.isUserInteractionEnabled = false
        h1.center.y = self.view.center.y
        view.addSubview(h1)
    }
    

    

}
