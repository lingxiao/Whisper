//
//  ModalLib.swift
//  Whisper
//
//  Created by Xiao Ling on 2/28/21.
//

import Foundation
import UIKit
import SwiftEntryKit


//MARK:- system message

/*
 @use: warn user of undesired event
 */
func ToastWarn( title: String = "", body: String = ""){
    let ( attributes, contentView ) = topToastFactory( title: title, body: body, imgName: "error-alert")
    SwiftEntryKit.display(entry: contentView, using: attributes)
}


func ToastSuccess( title: String = "", body: String = ""){
    let ( attributes, contentView ) = topToastFactory( title: title, body: body, imgName: nil)
    SwiftEntryKit.display(entry: contentView, using: attributes)
}

public func ToastExplain( title: String, body: String, btn: String, _ then: @escaping() -> Void ){
    
    // Generate textual content
    let tit = UIFont(name: FontName.bold, size: AppFontSize.body2)!
    let bod = UIFont(name: FontName.regular, size: AppFontSize.footer)!
    let buttonFont = UIFont(name: FontName.bold, size: AppFontSize.footer)!

    let title = EKProperty.LabelContent(text: title, style: .init(font: tit, color: EKColor(Color.primary_dark)))
    let description = EKProperty.LabelContent(text: body, style: .init(font: bod, color: EKColor(Color.primary_dark)))
    let simpleMessage = EKSimpleMessage(image: nil, title: title, description: description)
    
    
    // Ok Button - Make transition to a new entry when the button is tapped
    let okButtonLabelStyle = EKProperty.LabelStyle(font: buttonFont, color: EKColor(Color.secondary_dark))
    let okButtonLabel = EKProperty.LabelContent(text: btn, style: okButtonLabelStyle)
    
    let okButton = EKProperty.ButtonContent(
        label: okButtonLabel,
        backgroundColor: .clear,
        highlightedBackgroundColor: EKColor(Color.graySecondary)
    ) {
        then()
        SwiftEntryKit.dismiss()
    }

    let buttonsBarContent = EKProperty.ButtonBarContent(
        with: okButton,
        separatorColor: EKColor(Color.grayTertiary),
        buttonHeight: 60,
        expandAnimatedly: true
    )
    
    // Generate the content
    let alertMessage = EKAlertMessage(simpleMessage: simpleMessage, imagePosition: .left, buttonBarContent: buttonsBarContent)
    let contentView = EKAlertMessageView(with: alertMessage)
    
    // attributes
    var attributes = EKAttributes.centerFloat
    attributes.entryBackground = .color(color: EKColor(Color.primary))
    attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.3), scale: .init(from: 1, to: 0.7, duration: 0.7)))
    attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 10, offset: .zero))
    attributes.statusBar = .dark
    attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
    attributes.displayDuration = 1000
    SwiftEntryKit.display(entry: contentView, using: attributes)

}

public func ToastBlurb( title: String, body: String ){

    // Generate textual content
    let tit = UIFont(name: FontName.bold, size: AppFontSize.H3)!
    let bod = UIFont(name: FontName.regular, size: AppFontSize.footerBold)!
    let buttonFont = UIFont(name: FontName.bold, size: AppFontSize.footer)!

    let title = EKProperty.LabelContent(text: title, style: .init(font: tit, color: EKColor(Color.primary_dark)))
    let description = EKProperty.LabelContent(text: body, style: .init(font: bod, color: EKColor(Color.primary_dark)))
    let simpleMessage = EKSimpleMessage(image: nil, title: title, description: description)
    
    // btn
    // Ok Button - Make transition to a new entry when the button is tapped
    let okButtonLabelStyle = EKProperty.LabelStyle(font: buttonFont, color: EKColor(Color.secondary_dark))
    let okButtonLabel = EKProperty.LabelContent(text: "Ok", style: okButtonLabelStyle)
    
    let okButton = EKProperty.ButtonContent(
        label: okButtonLabel,
        backgroundColor: .clear,
        highlightedBackgroundColor: EKColor(Color.graySecondary)
    ) {
        SwiftEntryKit.dismiss()
    }

    let buttonsBarContent = EKProperty.ButtonBarContent(
        with: okButton,
        separatorColor: EKColor(Color.primary),
        buttonHeight: 60,
        expandAnimatedly: false
    )
    
    // Generate the content
    let alertMessage = EKAlertMessage(simpleMessage: simpleMessage, imagePosition: .left, buttonBarContent: buttonsBarContent)
    let contentView = EKAlertMessageView(with: alertMessage)
    
    // attributes
    var attributes = EKAttributes.centerFloat
    attributes.entryBackground = .color(color: EKColor(Color.primary))
    attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.3), scale: .init(from: 1, to: 0.7, duration: 0.7)))
    attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 10, offset: .zero))
    attributes.statusBar = .dark
    attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
    attributes.displayDuration = 1000
    SwiftEntryKit.display(entry: contentView, using: attributes)
    
}



public func bottomToastFactory( ratio: CGFloat = 1/2, displayDuration: Double = 10000 ) -> EKAttributes {

    var attributes = EKAttributes.bottomNote // .bottomFloat
    attributes.entryBackground = .color(color: EKColor(Color.primary))
    attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.3), scale: .init(from: 1, to: 0.7, duration: 0.7)))
    attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 10, offset: .zero))
    attributes.statusBar = .dark
    attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
    attributes.displayDuration = displayDuration
    attributes.roundCorners = EKAttributes.RoundCorners.top(radius:40)

    // this allows the entry to be shown with bottomToats
    attributes.precedence = .override(priority: .normal, dropEnqueuedEntries: false)


    // control aspect ratio
    let widthConstraint  = EKAttributes.PositionConstraints.Edge.ratio(value: 1.0)
    let heightConstraint = EKAttributes.PositionConstraints.Edge.ratio(value: ratio)
    attributes.positionConstraints.size = .init(width: widthConstraint, height: heightConstraint)
    
    return attributes
    
}


public func centerToastFactory( ratio: CGFloat = 1/2, displayDuration: Double = 10000 ) -> EKAttributes {

    var attributes = EKAttributes.centerFloat
    attributes.entryBackground = .color(color: EKColor(Color.transparent)) //offWhiteLight))
    attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.3), scale: .init(from: 1, to: 0.7, duration: 0.7)))
    attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 10, offset: .zero))
    attributes.statusBar = .dark
    attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
    attributes.displayDuration = displayDuration
    attributes.roundCorners = EKAttributes.RoundCorners.top(radius:40)

    // this allows the entry to be shown with bottomToats
    attributes.precedence = .override(priority: .normal, dropEnqueuedEntries: false)


    // control aspect ratio
    let widthConstraint  = EKAttributes.PositionConstraints.Edge.ratio(value: 1.0)
    let heightConstraint = EKAttributes.PositionConstraints.Edge.ratio(value: ratio)
    attributes.positionConstraints.size = .init(width: widthConstraint, height: heightConstraint)
    
    return attributes
    
}


private func topToastFactory( title: String, body: String, imgName: String? ) -> ( EKAttributes, EKNotificationMessageView ) {
    
    // modal prop
    var attributes = EKAttributes.topFloat
    attributes.entryBackground = .color(color: EKColor(Color.white))
    attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.3), scale: .init(from: 1, to: 0.7, duration: 0.7)))
    attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 10, offset: .zero))
    attributes.statusBar = .dark
    attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
    attributes.displayDuration = 6

    // prevent existing entries from being dropped
    attributes.precedence = .override(priority: .normal, dropEnqueuedEntries: true)

    
    // view prop
    let tit = UIFont(name: FontName.bold, size: AppFontSize.footerBold)!
    let bod = UIFont(name: FontName.regular, size: AppFontSize.footer)!
    let title = EKProperty.LabelContent(text: title, style: .init(font: tit, color: EKColor(Color.primary_dark)))
    let description = EKProperty.LabelContent(text: body, style: .init(font: bod, color: EKColor(Color.primary_dark)))

    var image : EKProperty.ImageContent?
    
    if let name = imgName {
        if let file = UIImage(named: name) {
            image = EKProperty.ImageContent(image: file, size: CGSize(width: 30, height: 30))
        }
    }
    
    let simpleMessage = EKSimpleMessage(image: image, title: title, description: description)
    let notificationMessage = EKNotificationMessage(simpleMessage: simpleMessage)
    let contentView = EKNotificationMessageView(with: notificationMessage)
    
    return (attributes, contentView)


}

