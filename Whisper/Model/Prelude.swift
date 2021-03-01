//
//  Prelude.swift
//  byte
//
//  Created by Xiao Ling on 5/23/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import AVFoundation


/*
 @Use: common data types
*/
enum Either<A, B>{
    case Left(A)
    case Right(B)
}



/*
 @use: map fn onto parametirzed types
 @NOTE: this function is hard to use w/o fn composition
 */
func mapEither<A,B,C,D>( on either: Either<A,B>, le: (A) -> C, rt: (B) -> D ){
    switch(either){
    case .Left( let lv ):
        let _ = le(lv)
    case .Right(let rv):
        let _ = rt(rv)
    }
    
}

// @trivial function
func memptyFn<T>( _ t: T ) -> Void {
    return
}


// @use: turn [xs] into [[xs]]
func overlay<T, U>(_ array: [[T]], values: [U]) -> [[U]] {
    var iter = values.makeIterator()
    return array.map { $0.compactMap { _ in iter.next() }}
}



//MARK:- firestore common functions


/*
 @Use: upload image to firebase storage
 */
func uploadImageToFireStorage( to path: String,  with data: Data?, _ complete: @escaping Completion ){
    
    if ( data == nil ){ return complete(false,"") }
    
    let storageRef = AppDelegate.shared.storeRef!.reference().child(path)

    storageRef.putData( data!, metadata:nil){ (metadata,error) in

        guard let metadata = metadata else {
            return complete(false,"")
        }

        storageRef.downloadURL { (url, error) in
            guard let downloadURL = url else {
                return complete(false, "")
            }
            let url = String(describing: downloadURL)
            return complete( true, url )
        }
    }
}

//MARK:- upload video


func convertVideo(toMPEG4FormatForVideo inputURL: URL, outputURL: URL, handler: @escaping (AVAssetExportSession) -> Void) {
    //try! FileManager.default.removeItem(at: outputURL as URL)
    
    let asset = AVURLAsset(url: inputURL as URL, options: nil)

    let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mp4
    exportSession.exportAsynchronously(completionHandler: {
        handler(exportSession)
    })
}



//MARK:- hex code

struct ShortCodeGenerator {

    private static let base62chars = [Character]("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    private static let maxBase : UInt32 = 62

    static func getCode(withBase base: UInt32 = maxBase, length: Int) -> String {
        var code = ""
        for _ in 0..<length {
            let random = Int(arc4random_uniform(min(base, maxBase)))
            code.append(base62chars[random])
        }
        return code
    }
    
    static func mkInviteCode() -> String {
        return ShortCodeGenerator.getCode(length: 6)
    }
}
