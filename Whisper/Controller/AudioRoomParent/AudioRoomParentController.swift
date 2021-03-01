//
//  AudioRoomParentController.swift
//  byte
//
//  Created by Xiao Ling on 1/9/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


//MARK:- enum

enum AudioRoomParentCellKind {
    case audioRoom
    case explore
    case breakoutRoom
}

protocol AudioRoomParentDelegate {
    func didShowFlashCardDeck() -> Void
}

//MARK:- class


class AudioRoomParentController: UIViewController, AudioRoomParentDelegate {
    
    var club: Club?
    var room: Room?
    var dataSource: [AudioRoomParentCellKind] = [.audioRoom, .breakoutRoom]

    // views
    private var hand: TinderButton?
    private var colView: UICollectionView?
    private var edgeInsets = UIEdgeInsets(top: -15, left: 0, bottom: 0, right: 0)

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func config( with club: Club? ){

        self.club = club
        self.room = club?.getRootRoom()
        self.view.backgroundColor = Color.primary
        
        if let club = club {
            if club.type == .ephemeral {
                dataSource = [.audioRoom]
            }
        }

        layout()
        reload()

        if UserAuthed.shared.did_drag_audio_room == false && self.dataSource.count > 1 {
            showHandGesture( down: false ){
                UserAuthed.shared.didDragAudioRoom()
            }
        }
    }
    
    func didShowFlashCardDeck(){
        if UserAuthed.shared.did_drag_deck == false {
            showHandGesture( down: true ){
                self.tap()
                UserAuthed.shared.didDragDeck()
            }
        }
    }
    
   
    func reload(){
        colView?.reloadData()
    }
    
    private func showHandGesture( down: Bool, _ then: @escaping() -> Void){
        
        self.hand?.removeFromSuperview()
        
        let f = self.view.frame
        let R = f.width/4
        let v = TinderButton()
        v.frame = CGRect(x: (f.width-R)/2, y: (f.height-R)/2, width: R, height: R)
        v.changeImage(to: "handdrag", alpha: 1.0, scale: 1, color: Color.grayPrimary)
        v.backgroundColor = UIColor.clear
        v.alpha = 0.0
        view.addSubview(v)
        self.hand = v
        
        func hide() { self.hand?.alpha = 0.0 }
        func show() { self.hand?.alpha = 1.0 }
        func left() { self.hand?.frame = CGRect(x: f.width/2-R   , y: (f.height-R)/2, width: R, height: R) }
        func right(){ self.hand?.frame = CGRect(x: f.width/2+R   , y: (f.height-R)/2, width: R, height: R) }
        func downF(){ self.hand?.frame = CGRect(x: (f.width-R)/2 , y: f.height/2+R  , width: R, height: R) }
        func center(){ self.hand?.frame = CGRect(x: (f.width-R)/2, y: (f.height-R)/2, width: R, height: R) }
        
        if down {
            
            runAnimation( with: show, for: 0.25 ){
                runAnimation( with: right, for: 0.5 ){
                    runAnimation( with: center, for: 0.5 ){
                        runAnimation( with: downF, for: 0.5 ){
                            runAnimation( with: hide, for: 0.25 ){
                                self.hand?.removeFromSuperview()
                                self.hand = nil
                                then()
                            }
                        }
                    }
                }
            }
            
        } else {
            
            runAnimation( with: show, for: 0.25 ){
                runAnimation( with: left, for: 0.5 ){
                    runAnimation( with: hide, for: 0.25 ){
                        self.hand?.removeFromSuperview()
                        self.hand = nil
                        then()
                    }
                }
            }
        }

    }
    
    private func tap(){
     
        self.hand?.removeFromSuperview()
        
        let f = self.view.frame
        let R = f.width/4
        let v = TinderButton()
        v.frame = CGRect(x: f.width - 2 - R, y: (f.height-R)/2, width: R, height: R)
        v.changeImage(to: "tap", alpha: 1.0, scale: 1, color: Color.grayPrimary)
        v.backgroundColor = UIColor.clear
        v.alpha = 0.0
        view.addSubview(v)
        view.bringSubviewToFront(v)
        self.hand = v
        
        func show() { self.hand?.alpha = 1.0 }
        func hide() { self.hand?.alpha = 0.0 }
        runAnimation( with: show, for: 2/3 ){
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                runAnimation( with: hide, for: 0.24 ){
                    self?.hand?.removeFromSuperview()
                    self?.hand = nil
                }
            }
        }
    }

    private func layout(){
        
        let f = self.view.frame
        
        // layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = edgeInsets
        layout.itemSize = CGSize(width: f.width, height: f.height)
        
        // create
        let collection = UICollectionView(frame:CGRect(x:0,y:0,width:f.width,height:f.height), collectionViewLayout:layout)

        // style
        collection.backgroundColor = Color.transparent
        collection.showsHorizontalScrollIndicator = false
        collection.alwaysBounceHorizontal = false
        collection.isPagingEnabled = true
        collection.bounces = false

        // mount + register cell
        self.view.addSubview(collection)
        self.colView = collection
        colView?.register(AudioRoomParentCell.self, forCellWithReuseIdentifier: AudioRoomParentCell.identifier)
        
        // set delegates
        colView?.delegate = self
        colView?.dataSource = self
    }
}


//MARK:- layout

extension AudioRoomParentController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let row = indexPath.row
        let idx = dataSource[row]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AudioRoomParentCell", for: indexPath) as! AudioRoomParentCell
        cell.config(with: self.club, room: self.room, kind: idx)
        cell.delegate = self
        return cell
    }
}


//MARK:- cell -

/*
 @Use: display user's screen
*/
class AudioRoomParentCell: UICollectionViewCell, AudioRoomParentDelegate {

    static var identifier: String = "AudioRoomParentCell"
    
    var code: Int = 0
    var widget: ClubWidgets?
    
    var roomVC: AudioRoomController?
    var exploreVC: ExploreParentController?
    var breakoutVC: BreakoutDirectory?
    var delegate: AudioRoomParentDelegate?
    
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
    }
    
    func config( with club: Club?, room: Room?, kind: AudioRoomParentCellKind ){
        switch kind {
        case .audioRoom:
            let vc = AudioRoomController()
            vc.view.frame = UIScreen.main.bounds
            vc.config(with: room, club: club)
            addSubview(vc.view)
            self.roomVC = vc
        case .explore:
            let vc = ExploreParentController()
            vc.view.frame = UIScreen.main.bounds
            vc.config(with: club, room: room)
            vc.delegate = self
            addSubview(vc.view)
            self.exploreVC = vc
        case .breakoutRoom:
            let vc = BreakoutDirectory()
            vc.view.frame = UIScreen.main.bounds
            vc.config(with: club)
            //vc.delegate = self
            addSubview(vc.view)
            self.breakoutVC = vc
        }

    }
    
    func didShowFlashCardDeck(){
        delegate?.didShowFlashCardDeck()
    }
}


