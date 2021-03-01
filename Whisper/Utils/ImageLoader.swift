//
//  ImageLoader.swift
//  byte
//
//  Created by Xiao Ling on 5/18/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit.UIImage
import Combine

public final class ImageLoader {

    public static let shared = ImageLoader()

    private let cache: ImageCacheType
    private lazy var backgroundQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 5
        return queue
    }()
    
    // record loaded urls
    private var record : [URL:Bool] = [:]

    public init(cache: ImageCacheType = ImageCache()) {
        self.cache = cache
    }
    
    /*
     @use: set imageView with UIImage with animation
    */
    public func injectImage(
          from url: URL?
        , to imgView: UIImageView?
        , sizeToFit: CGSize = CGSize(width:0,height:0)
        , shouldFocusOnFace: Bool = true
        , complete: @escaping (Bool) -> Void
        , for duration: TimeInterval = 0.3
    ){
        
        guard let imgView = imgView else {
            return complete(false)
        }

        guard let url = url else {
            imgView.backgroundColor = Color.grayQuaternary
            return
        }

        // loads image from server or local cache. This will throw error?
        let source : AnyPublisher<UIImage?, Never> = ImageLoader.shared.loadImage(from: url)

        let _ = source.sink { [unowned self] image in
            
            guard let image = image else {
                imgView.backgroundColor = Color.grayQuaternary
                return
            }
            
            imgView.image = image

        }
    }
    
    private func firstLoad(for url: URL ) -> Bool {
        if let b = self.record[url] {
            return b
        } else {
            return false
        }
    }
    
    // @use: load image and crop
    public func loadImageAndCrop(
        from url: URL?,
        width  w: CGFloat,
        height h: CGFloat,
        _ then  : @escaping ( UIImage? ) -> Void
    ){
        guard let url = url else { return then(nil) }
        let source : AnyPublisher<UIImage?, Never> = ImageLoader.shared.loadImage(from: url)
        let _ = source.sink { [unowned self] image in
            guard let image = image else { return then(nil) }
            let sm = UIImage.resizeImage(with: image, scaledToFill:  CGSize(width:w,height:h))
            then(sm)
        }
    }
       
    
    // @Use: force lazy loading to complete
    public func forceEval( on source : AnyPublisher<UIImage?, Never> ){
        let _ = source.sink { [unowned self] image in return }
    }

    public func loadImage(from url: URL) -> AnyPublisher<UIImage?, Never> {
        if let image = cache[url] {
            return Just(image).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { (data, response) -> UIImage? in return UIImage(data: data) }
            .catch { error in return Just(nil) }
            .handleEvents(receiveOutput: {[unowned self] image in
                guard let image = image else { return }
                self.cache[url] = image
            })
            .subscribe(on: backgroundQueue)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

//MARK:- UIImage extensions

func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {

        let cgimage = image.cgImage!
        let contextImage: UIImage = UIImage(cgImage: cgimage)
        let contextSize: CGSize = contextImage.size
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)

        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }

        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)

        // Create bitmap image from context using the rect
        let imageRef: CGImage = cgimage.cropping(to: rect)!

        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)

        return image
    }


extension UIImage {
    
    func crop(to:CGSize) -> UIImage {

        guard let cgimage = self.cgImage else { return self }

        let contextImage: UIImage = UIImage(cgImage: cgimage)

        guard let newCgImage = contextImage.cgImage else { return self }

        let contextSize: CGSize = contextImage.size

        //Set to square
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        let cropAspect: CGFloat = to.width / to.height

        var cropWidth: CGFloat = to.width
        var cropHeight: CGFloat = to.height

        if to.width > to.height { //Landscape
            cropWidth = contextSize.width
            cropHeight = contextSize.width / cropAspect
            posY = (contextSize.height - cropHeight) / 2
        } else if to.width < to.height { //Portrait
            cropHeight = contextSize.height
            cropWidth = contextSize.height * cropAspect
            posX = (contextSize.width - cropWidth) / 2
        } else { //Square
            if contextSize.width >= contextSize.height { //Square on landscape (or square)
                cropHeight = contextSize.height
                cropWidth = contextSize.height * cropAspect
                posX = (contextSize.width - cropWidth) / 2
            }else{ //Square on portrait
                cropWidth = contextSize.width
                cropHeight = contextSize.width / cropAspect
                posY = (contextSize.height - cropHeight) / 2
            }
        }

        let rect: CGRect = CGRect(x: posX, y: posY, width: cropWidth, height: cropHeight)

        // Create bitmap image from context using the rect
        guard let imageRef: CGImage = newCgImage.cropping(to: rect) else { return self}

        // Create a new image based on the imageRef and rotate back to the original orientation
        let cropped: UIImage = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)

        UIGraphicsBeginImageContextWithOptions(to, false, self.scale)
        cropped.draw(in: CGRect(x: 0, y: 0, width: to.width, height: to.height))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized ?? self
      }
}


/*
 
 
 if let image = image {

     let fixed = image // image.fixOrientation()
     imgView.alpha = firstLoad(for: url) ? 0.0 : 1.0
     imgView.image = fixed

     if shouldFocusOnFace {
         //imgView.focusOnFaces = true
     }

     if sizeToFit.width > 0 && sizeToFit.height > 0 {
         let resized = UIImage.resizeImage(with: fixed, scaledToFill: sizeToFit)
         imgView.image = resized
     }
     
     if firstLoad(for: url){
         func fn(){ imgView.alpha = 1.0 }
         runAnimation( with: fn, for: 0.15 ){
             self.record[url] = true
         }
     }
 
 */
