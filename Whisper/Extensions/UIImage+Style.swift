//
//  UIImage+Color.swift
//  byte
//
//  Created by Xiao Ling on 7/5/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit



//MARK:- UIImageView extension


extension UIImageView {

    func makeRounded() -> UIImageView {

        self.layer.borderWidth = 0.5
        self.layer.masksToBounds = false
        self.layer.borderColor = Color.primary.cgColor
        self.layer.cornerRadius = self.frame.width/2
        self.clipsToBounds = true
        
        // see https://developer.apple.com/documentation/uikit/uiview/contentmode
        self.contentMode = .scaleAspectFill
        
        return self
    }
    
    func round() -> UIImageView {        
        self.layer.borderWidth = 0.0 //5
        self.layer.masksToBounds = false
        self.layer.cornerRadius = self.frame.width/2
        self.clipsToBounds = true
        self.contentMode = .scaleAspectFill
        return self
    }
    
    func corner( with r: CGFloat ) -> UIImageView {
        self.layer.borderWidth = 0.0
        self.layer.masksToBounds = false
        self.layer.cornerRadius = r
        self.clipsToBounds = true
        self.contentMode = .scaleAspectFill
        return self
    }
        
    func border( width: CGFloat, color: CGColor ) -> UIImageView {
        self.layer.borderWidth = width
        self.layer.borderColor = color
        return self
        
    }
    
    func colored(_ color: UIColor) -> UIImageView {
        let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
        return self
    }
    
    func doTap( on obj : Any, with fn: Selector ) -> UIImageView {
        let singleTap = UITapGestureRecognizer(target: obj, action: fn)
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(singleTap)
        return self
    }

}


//MARK:- extend image it self

extension UIImage {
    
    // resize image to fit viewport while keeping aspect ratio
    class func resizeImage(with image: UIImage?, scaledToFill size: CGSize) -> UIImage? {
       let scale: CGFloat = max(size.width / (image?.size.width ?? 0.0), size.height / (image?.size.height ?? 0.0))
       let width: CGFloat = (image?.size.width ?? 0.0) * scale
       let height: CGFloat = (image?.size.height ?? 0.0) * scale
       let imageRect = CGRect(x: (size.width - width) / 2.0, y: (size.height - height) / 2.0, width: width, height: height)
       UIGraphicsBeginImageContextWithOptions(size, false, 0)
       image?.draw(in: imageRect)
       let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
       UIGraphicsEndImageContext()
       return newImage
    }

    func alpha(_ value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

    /// @Todo: this blurs the image for some reason
    func imageWithColor(_ color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.setFill()

        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)

        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    
    }
    
    func fixOrientation() -> UIImage? {
        if self.imageOrientation == UIImage.Orientation.up {
            return self
        }

        UIGraphicsBeginImageContext(self.size)
        self.draw(in: CGRect(origin: .zero, size: self.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage
    }
    
    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0,
                                 y: rotatedSize.height / 2.0)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -origin.y, y: -origin.x,
                            width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return rotatedImage ?? self
        }

        return self
    }

    func aspectFittedToHeight(_ newHeight: CGFloat) -> UIImage{
        let scale = newHeight / self.size.height
        let newWidth = self.size.width * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    
}

