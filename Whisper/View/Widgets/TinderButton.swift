//
//  TinderButton.swift
//  byte
//
//  Created by Xiao Ling on 12/4/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import PopBounceButton

//MARK:- icon button

class TinderButton: PopBounceButton {
    
    var code: String = ""

  override init() {
    super.init()
    adjustsImageWhenHighlighted = false
    backgroundColor = .white
    layer.masksToBounds = true
  }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.cornerRadius = frame.width / 2
        applyShadow(radius: 0.2 * bounds.width, opacity: 0.05, offset: CGSize(width: 0, height: 0.15 * bounds.width))
    }
    
    public func changeImage(
          to name: String
        , alpha: CGFloat = 2/3
        , scale: CGFloat = 1/2
        , color : UIColor = Color.primary_dark
    ){
        guard let img = UIImage(named: name) else { return }
        let R = self.frame.width
        let _ = img.alpha( alpha )
        let colored = img.imageWithColor(color)
        let sm = UIImage.resizeImage( with: colored, scaledToFill: CGSize(width: R*scale, height: R*scale))
        self.setImage(sm, for: .normal)
    }
}


//MARK:- text button

class TinderTextButton: PopBounceButton {
    
    var textLabel: VerticalAlignedLabel?
    var fontClass: UIFont!
    var code: String = ""
    private var labelText: String =  ""

    override init() {
        super.init()        
        adjustsImageWhenHighlighted = false
        backgroundColor = .white
        layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.cornerRadius = frame.height/2
    }
    
    public func config(
        with text: String,
        color : UIColor = Color.secondary_dark,
        font: UIFont? = nil
    ){
        self.labelText = text
        if let font = font {
            self.fontClass = font
            setText(to: text, color: color)
        } else {
            self.fontClass = UIFont(name: FontName.bold, size: AppFontSize.footerBold)!
            setText(to: text, color: color)
        }
    }
    
    public func setText(to text: String, color: UIColor = Color.secondary_dark ){

        if self.textLabel == nil {

            let f = self.frame
            let label : VerticalAlignedLabel = VerticalAlignedLabel()
            label.frame = CGRect( x: 0, y: 0, width: f.width, height: f.height)
            label.font = self.fontClass
            label.textAlignment = .center
            label.textColor = color
            label.text = text
            self.addSubview(label)
            self.textLabel = label

        } else {
            textLabel?.text = text
        }
    }
    
    public func underline(){
        let str = self.textLabel?.text ?? self.labelText
        let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.thick.rawValue]
        let underlineAttributedString = NSAttributedString(string: str, attributes: underlineAttribute)
        self.textLabel?.attributedText = underlineAttributedString
    }
    
    public func rmvUnderline(){
        let str = self.textLabel?.text ?? self.labelText
        self.textLabel?.attributedText = nil
        self.textLabel?.text = str
    }

    
}

