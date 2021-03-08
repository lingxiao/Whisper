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

        self.view.backgroundColor = UIColor.white

        let f = view.frame
        let ht = f.width*0.40
        
        /*let h1 = UILabel(frame: CGRect(x: 0, y: 0, width: f.width, height: ht))
        h1.textAlignment = .center
        h1.text = "W"
        h1.font = UIFont(name: FontName.icon, size: AppFontSize.H1*2 )
        h1.textColor = UIColor.white
        h1.center = view.center
        view.addSubview(h1)*/

        let im = UIImage(named: "triangle-2")!
        let colored = im.imageWithColor(UIColor.black)

        let imgl = UIImageView(frame: CGRect(x: 0, y: 0, width: ht, height: ht))
        imgl.center.y = self.view.center.y
        imgl.center.x = self.view.center.x - ht/6
        imgl.image = colored
        view.addSubview(imgl)
        
        let imgr = UIImageView(frame: CGRect(x: 0, y: 0, width: ht, height: ht))
        imgr.center.y = self.view.center.y
        imgr.center.x = self.view.center.x + ht/6
        imgr.image = colored
        view.addSubview(imgr)
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
