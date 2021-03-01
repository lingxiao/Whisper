//
//  WidgetRow.swift
//  byte
//
//  Created by Xiao Ling on 1/2/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


protocol WidgetRowDelegate {
    func onTapWidget( at widget: ClubWidgets? ) -> Void
}


class WidgetRow: UITableViewCell, WidgetRowCellDelegate {
    
    // storyboard identifier
    static let identifier = "WidgetRow"

    var club: Club?
    var room: Room?
    var dataSource: [ClubWidgets] = [.flashCards]
    
    var delegate: WidgetRowDelegate?
    
    // views
    private var offset : Int = 0
    private var colView: UICollectionView?
    private var edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    override func prepareForReuse(){
        self.colView?.removeFromSuperview()
    }
    
    
    func config( with club: Club?, room: Room? ){
        
        self.club = club
        self.room = room
        self.backgroundColor = Color.primary
        
        // hard-code podcast into room if you're
        // in the sound-room club
        /*if let club = self.club {
            dataSource = club.widgets
        }*/
        layout()
        colView?.reloadData()
    }
    
    func reload(){
        colView?.reloadData()
    }
    
    func didTapWidgetCell( widget: ClubWidgets? ){
        delegate?.onTapWidget(at: widget)
    }

    
    private func layout(){
        
        let f = self.frame
        let ht = f.height - 20
        
        // layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = edgeInsets
        layout.itemSize = CGSize(width: ht+20, height: ht)
        
        // create
        let collection = UICollectionView(
              frame: CGRect(
                  x: 0
                , y: 0
                , width: f.width
                , height: f.height
            )
            , collectionViewLayout:layout
        )

        // style
        collection.backgroundColor = Color.transparent
        collection.showsHorizontalScrollIndicator = false
        collection.alwaysBounceHorizontal = true

        // mount + register cell
        self.addSubview(collection)
        self.colView = collection
        colView?.register(WidgetRowCell.self, forCellWithReuseIdentifier: WidgetRowCell.identifier)
        
        // set delegates
        colView?.delegate = self
        colView?.dataSource = self
    }
}


//MARK:- layout

extension WidgetRow: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let row = indexPath.row
        let widget = dataSource[row]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WidgetRowCell", for: indexPath) as! WidgetRowCell
        cell.delegate = self
        cell.config(with: widget, club: club, room: room)
        return cell
    }
}



//MARK:- cell-


protocol WidgetRowCellDelegate {
    func didTapWidgetCell( widget: ClubWidgets? ) -> Void
}


/*
 @Use: display user's screen
*/
class WidgetRowCell: UICollectionViewCell {

    static var identifier: String = "WidgetRowCell"
    
    var parent: UIView?
    var code: Int = 0
    var widget: ClubWidgets?
    var delegate: WidgetRowCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /*
     @use: reset all child views
     https://stackoverflow.com/questions/54188027/how-to-reset-uicollectionview-in-swift
     */
    override func prepareForReuse() {
        super.prepareForReuse()
        parent?.removeFromSuperview()
    }
    
    func config( with widget: ClubWidgets?, club: Club?, room: Room? ){
        
        guard let widget = widget else { return }
        self.widget = widget
            
        let f = self.frame
        let pv = UIView(frame: CGRect(x: 20, y: 5, width: f.width-20, height: f.height))
        pv.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 20)
        addSubview(pv)
        self.parent = pv

        switch widget {
        case .flashCards:
            layoutFlashCard(on: pv)
        case .music:
            layoutMusic(on: pv, club: club, room: room)
        default:
            pv.backgroundColor = Color.primary
        }
        
        let _ = self.tappable(with: #selector(onTap))
    }
    
    @objc func onTap(){
        delegate?.didTapWidgetCell( widget: self.widget )
    }
    
    @objc func handleTapNotes( _ button: TinderButton ){
        delegate?.didTapWidgetCell( widget: self.widget )
    }
    
    private func layoutFlashCard(on pv: UIView){
        
        pv.backgroundColor = Color.blue1

        let colr = Color.blue1.darker(by: 50)
        
        let f = pv.frame
        let ht = AppFontSize.H2 + 10
        let font: UIFont = UIFont(name: FontName.bold, size: AppFontSize.H2)!
        var dy = f.height - 10 - 2*ht

        let v = UITextView(frame:CGRect(x:5,y:dy,width:f.width-10,height:ht))
        v.font = font
        v.text = "Flash"
        v.textColor = colr
        v.textAlignment = .right
        v.backgroundColor = UIColor.clear
        v.isUserInteractionEnabled = false
        pv.addSubview(v)

        dy += ht
        
        let w = UITextView(frame:CGRect(x:5,y:dy,width:f.width-10,height:ht))
        w.font = font
        w.text = "Cards"
        w.textColor = colr
        w.textAlignment = .right
        w.backgroundColor = UIColor.clear
        w.isUserInteractionEnabled = false
        pv.addSubview(w)
    }
    
    
    private func layoutMusic( on pv: UIView, club: Club?, room: Room? ){
        
        pv.backgroundColor = Color.redDark

        let f = pv.frame
        let img = TinderButton()
        img.frame = CGRect(x: 20, y: 20, width: f.width-40, height: f.width-40)
        img.changeImage(to: "music", alpha: 1.0, scale: 2/3, color: Color.primary)
        img.backgroundColor = Color.redDark
        img.center = pv.center
        addSubview(img)
        img.addTarget(self, action: #selector(handleTapNotes), for: .touchUpInside)
    }
}


