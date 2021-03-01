//
//  Color.swift
//  byte
//
//  Created by Xiao Ling on 5/22/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//  see: https://github.com/andrewsoohwanlee/gentle/blob/dcdef320ec600d426eb413ab7727969fa3c5b87f/flutter-app/lib/Theme.dart#L7
//

import UIKit
import Foundation


/*
    @Use: app colors. Stick to this pallet
    source: https://www.design-seeds.com/tag/bone/
*/

struct Color {
    
    // transparent
    static let transparent = UIColor(red:0/256, green:0/256, blue:0/256,alpha:0.0)
    
    static let white = UIColor(rgb:0xfffefc)
    static let black = UIColor(rgb:0x21242C)
    
    // primary background color and textcolor
    static let primary = UIColor(rgb:0xfefaf6)
    static let primary_dark = UIColor(rgb:0x676260)
    
    static let secondary = UIColor.white.darker(by: 10)
    static let secondary_dark = UIColor(rgb:0x4d312e)

    static let tertiary_dark = UIColor(rgb:0x1A1A1A)

    // accents
    static let greenLight = UIColor(rgb:0xe3efec)
    static let greenDark  = UIColor(rgb:0x63b8af)
    static let redDark    = UIColor(rgb:0xff414d)
    static let redLite    = UIColor(rgb:0xfee1e3)
    static let purpleLite = UIColor(rgb:0xa8b3f1)
    
    static let tan     = UIColor(rgb:0xFEFBE3)
    static let tan2    = UIColor(rgb:0xEDFDFC)
    static let purple2 = UIColor(rgb:0xF4EDFD)
    static let puprle3 = UIColor(rgb:0xFDEDEE)
    static let blue1   = UIColor(rgb:0xEEF5FF)

    // grays
    static let grayPrimary   = UIColor(rgb:0xb1adaf)
    static let graySecondary = UIColor(rgb:0xf6f6f5)
    static let grayTertiary  = UIColor(rgb:0xe3efec)
    static let grayQuaternary = UIColor(rgb:0xe5e3e2)

    // transparent 
    static let primary_transparent_A = UIColor(red:250/256, green:249/256, blue:249/256,alpha:0.25)
    static let primary_transparent_B = UIColor(red:250/256, green:249/256, blue:249/256,alpha:0.50)
    
}

let ACCENT_COLORS : [UIColor] = [
    UIColor.clear,
    Color.tan,
    Color.tan2,
    Color.purple2,
    Color.puprle3,
    Color.purpleLite,
    Color.blue1,
    Color.redLite,
    Color.graySecondary,
    Color.grayTertiary
]

// translate clor to db
func toColorDbCode( _ color : UIColor ) -> Int {
    if let idx = ACCENT_COLORS.firstIndex(of: color) {
        return Int(idx)
    } else {
        return 0
    }
}

func fromColorDbCode( _ k : Int ) -> UIColor {
    if k < 0 || k > ACCENT_COLORS.count - 1 {
        return UIColor.clear
    } else {
        return ACCENT_COLORS[k]
    }
}

//MARK:- extension

extension UIColor {

    convenience init(red: Int, green: Int, blue: Int) {
       assert(red >= 0 && red <= 255, "Invalid red component")
       assert(green >= 0 && green <= 255, "Invalid green component")
       assert(blue >= 0 && blue <= 255, "Invalid blue component")

       self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    convenience init(rgb: Int) {
       self.init(
           red: (rgb >> 16) & 0xFF,
           green: (rgb >> 8) & 0xFF,
           blue: rgb & 0xFF
       )
    }

    func lighter(by percentage: CGFloat = 10.0) -> UIColor {
        return self.adjust(by: abs(percentage))
    }

    func darker(by percentage: CGFloat = 10.0) -> UIColor {
        return self.adjust(by: -abs(percentage))
    }

    func adjust(by percentage: CGFloat) -> UIColor {
        var alpha, hue, saturation, brightness, red, green, blue, white : CGFloat
        (alpha, hue, saturation, brightness, red, green, blue, white) = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

        let multiplier = percentage / 100.0

        if self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let newBrightness: CGFloat = max(min(brightness + multiplier*brightness, 1.0), 0.0)
            return UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
        }
        else if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            let newRed: CGFloat = min(max(red + multiplier*red, 0.0), 1.0)
            let newGreen: CGFloat = min(max(green + multiplier*green, 0.0), 1.0)
            let newBlue: CGFloat = min(max(blue + multiplier*blue, 0.0), 1.0)
            return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: alpha)
        }
        else if self.getWhite(&white, alpha: &alpha) {
            let newWhite: CGFloat = (white + multiplier*white)
            return UIColor(white: newWhite, alpha: alpha)
        }

        return self
    }
}

//MARK: - color gradients


func primaryGradient( on view: UIView ){
    let backgroundGray = UIColor(red: 244 / 255, green: 247 / 255, blue: 250 / 255, alpha: 1)
    let gradientLayer = CAGradientLayer()
    gradientLayer.colors = [UIColor.white.cgColor, backgroundGray.cgColor]
    gradientLayer.frame = view.bounds
    view.layer.insertSublayer(gradientLayer, at: 0)
}

func secondaryGradient( on view: UIView ){
    let gradientLayer = CAGradientLayer()
    gradientLayer.colors = [ Color.primary.darker(by: 25), Color.primary.darker(by: 45) ]
    gradientLayer.frame = view.bounds
    view.layer.insertSublayer(gradientLayer, at: 0)
}



//MARK:- color options

struct ColorLib {
    
    static let ThreadsSepia = UIColor(rgb:0xfefcf3)
    static let ThreadsDark  = UIColor(rgb:0x4d312e)
    
    static let GentleGrayTertiary = UIColor(red:229/256, green:229/256, blue:234/256,alpha:1.0)
    static let GentleGrayPrimary   = UIColor(red:142/256, green:142/256, blue:147/256,alpha:1.0)
    static let GentleGraySecondary = UIColor(red:199/256, green:199/256, blue:204/256,alpha:1.0)
    static let GentleRed = UIColor(red:253/256, green:116/256, blue:113/256,alpha:1.0)
    
    static let RoadTripSepia = UIColor(rgb:0xfefaf6)
    static let RoadTripDark  = UIColor(rgb:0x676260)

    static let RoadTripGray1 = UIColor(rgb:0xc3c7c0)
    static let RoadTripGray2 = UIColor(rgb:0xe3efec)
    static let RoadTripGray3 = UIColor(rgb:0xf6f6f5)

    static let RoadTripGreen = UIColor(rgb:0x63b8af)

}

