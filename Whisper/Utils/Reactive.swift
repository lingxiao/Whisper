//
//  Reactive.swift
//  byte
//
//  Created by Xiao Ling on 5/25/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit



// let user something substantial has happened
func heavyImpact(){
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    generator.impactOccurred()
}

func mediumImpact(){
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
}


func lightImpact(){
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
}


/*
 @use: run animation function `with`
 */
func runAnimation( with: @escaping () -> Void, for dt: Double,  _ complete: @escaping () -> Void   ){
    UIView.animate(withDuration: dt,
                   delay: 0,
                   options: [.curveEaseInOut , .allowUserInteraction],
                   animations: {
                    with()
    },
                   completion: { finished in complete() }

    )
}



/*
 @use: system default toast message
 */
/*func configureToastAppearance( offset: CGFloat=100 ) {
    
    let appearance = ToastView.appearance()
    appearance.backgroundColor = Color.grayTertiary
    appearance.textColor = Color.primary_dark
    appearance.font = .boldSystemFont(ofSize: 16)
    appearance.textInsets = UIEdgeInsets(top: 15, left: 20, bottom: 15, right: 20)
    appearance.bottomOffsetPortrait = offset
    appearance.cornerRadius = 10
    //appearance.maxWidthRatio = 0.7
}
*/

func delay( for m : Double, _ then: @escaping () -> Void ){
    DispatchQueue.main.asyncAfter(deadline: .now() + m, execute: {
            then()
    })
}
