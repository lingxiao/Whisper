//
//  TagView.swift
//  byte
//
//  Created by Xiao Ling on 1/6/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


protocol TagViewDelegate {
    func onTapWidget( at widget: ClubWidgets? ) -> Void
}


private let cell_width : CGFloat = 100.0

class TagView: UIView {
    
    var club: Club?
    var deck: FlashCardDeck?
    var dataSource: [Int] = [0,1,2,3,4,5,6,7,8]
    var delegate: TagViewDelegate?
    
    // views
    private var offset : Int = 0
    private var colView: UICollectionView?
    private var edgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)


    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func config( club: Club?, deck: FlashCardDeck? ){
        
        self.backgroundColor = UIColor.clear

        self.deck = deck
        self.club = club
        layout()
        colView?.reloadData()
    }
    
    func reload(){
        colView?.reloadData()
    }
    
    func didTapWidgetCell(){
        //delegate?.onTapWidget(at: widget)
    }
    
    static func Height() -> CGFloat {
        let rht = AppFontSize.footer + 20
        return rht
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
        layout.itemSize = CGSize(width: cell_width, height: ht)
        
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
        collection.backgroundColor = UIColor.clear
        collection.showsHorizontalScrollIndicator = false
        collection.alwaysBounceHorizontal = true

        // mount + register cell
        self.addSubview(collection)
        self.colView = collection
        colView?.register(TagViewCell.self, forCellWithReuseIdentifier: TagViewCell.identifier)
        
        // set delegates
        colView?.delegate = self
        colView?.dataSource = self
    }
}


//MARK:- layout

extension TagView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let row = indexPath.row
        let _ = dataSource[row]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagViewCell", for: indexPath) as! TagViewCell
        cell.backgroundColor = Color.greenDark
//        cell.delegate = self
        cell.config()
        return cell
    }
}



//MARK:- cell-

/*
 @Use: display user's screen
*/
class TagViewCell: UICollectionViewCell {

    static var identifier: String = "TagViewCell"
    
    var parent: UIView?
    var code: Int = 0
    var widget: ClubWidgets?
    
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
    
    func config(){
        
        let _ = self.tappable(with: #selector(onTap))

//        let f = self.frame
//        let pv = UIView(frame: CGRect(x: 10, y: 0, width: f.width, height: f.height))
//        pv.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: f.height/4)
//        addSubview(pv)
//        self.parent = pv
//        pv.backgroundColor = Color.redDark

    }
    
    @objc func onTap(){

    }
    
    @objc func handleTapNotes( _ button: TinderButton ){

    }
    
}




