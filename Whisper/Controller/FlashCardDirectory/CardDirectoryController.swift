//
//  CardDirectoryController.swift
//  byte
//
//  Created by Xiao Ling on 1/2/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView



//MARK:- protocol + type

protocol DeckCoverViewDelegate {
    func didTap(on deck: FlashCardDeck? ) -> Void
}


enum ClubDirCell {
    case pad
    case headerA
    case headerB
    case headerC
    case cardRow
    case term_pad
}

typealias ClubDirData = [(ClubDirCell, [FlashCardDeck])]


//MARK:- class


/*
 @Use: renders my groups
*/
class CardDirectoryController: UIViewController, DeckCoverViewDelegate {
        
    // delegate + parent
    var delegate: ExploreParentProtocol?
    
    // style
    let headerHeight: CGFloat = 50
    let footerHeight: CGFloat = 80
    var statusHeight : CGFloat = 10.0
    var buttonHeight: CGFloat = AppFontSize.footer + 30

    // main child view
    var header: AppHeader?
    var tableView: UITableView?
    let refreshControl = UIRefreshControl()
    var blurView: UIView?
    var newDeckView: NewDeckViewSimple?
    var dotView: AwaitWidget? // NVActivityIndicatorView?

    // databasource
    var club: Club?
    var dataSource : ClubDirData = []
    
    override func viewDidLoad() {

        super.viewDidLoad()
        view.backgroundColor = Color.white
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
    }
    
    /*
     @use: call this to load data
    */
    func config( with club: Club?, room: Room? ){
        self.club = club
        layout()
        refresh()
        if let header = self.header {
            tableView?.tableHeaderView = header
        }
    }
    
    func refresh(){
        
        if GLOBAL_DEMO {
            refreshDemo()
        } else {
            refreshActual()
        }
    }
    
    private func refreshDemo(){
        var res : ClubDirData = [ (.pad,[]), (.headerB,[]) ]
        let decks : ClubDirData = to2DArray(yieldDummyDeck(for: 6)).map{ ( .cardRow, $0 ) }
        res.append(contentsOf: decks)
        res.append( (.term_pad,[]) )
        self.dataSource = res
        tableView?.reloadData()
    }
    
    
    private func refreshActual(){
        
        var res : ClubDirData = [ (.pad,[]) ]
        
        var ids : [DeckID] = []

        if let club = self.club {
            
            // get private decks that is visible only to this group
            let ps = FlashCardCache.shared.decks.values
                .filter{ $0.clubCanView( at: club) && $0.anyoneCanView() == false }
            ids.append( contentsOf: ps.map{ $0.uuid } )
            
            if ps.count > 0 {
                res.append( (.headerA, []) )
                for d in to2DArray(ps) {
                    res.append( (.cardRow, d ) )
                    res.append( (.pad, []) )
                }
            }


            // get tagged decks
            let xs = club.getMyDeck().filter{ ids.contains($0.uuid) == false }
            ids.append(contentsOf: xs.map{$0.uuid})
            
            if xs.count > 0 {
                res.append( (.headerB, []) )
                for d in to2DArray(xs) {
                    res.append( (.cardRow, d) )
                }
                res.append( (.pad, []) )
            }
        }

        let sm = FlashCardCache.shared.decks.values
            .filter{ ids.contains($0.uuid) == false }
            .filter{ $0.anyoneCanView() }
        
        if sm.count > 0 {
            res.append( (.headerC, []) )
            let tail = to2DArray(Array(sm))
            for d in tail {
                res.append( (.cardRow, d) )
            }
        }
        
        res.append( (.term_pad,[]) )
        
        self.dataSource = res
        tableView?.reloadData()
        
    }
    
    @objc private func ptr(_ sender: Any) {
        refresh()
        self.refreshControl.endRefreshing()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        /*if let headerView = self.tableView?.tableHeaderView as? AppHeader {
            headerView.scrollViewDidScroll(scrollView: scrollView)
        }*/
    }
    
    @objc func onTapOnBlurView(sender : UITapGestureRecognizer){
        hideNewDeck()
    }
    
    
    func didTap(on deck: FlashCardDeck? ){
        delegate?.onHandleTapDeck(on: deck)
    }    
    
    @objc func handleTapAdd( _ button: TinderButton ){
        showNewDeck()
    }
    
    private func showNewDeck(){

        newDeckView?.view.removeFromSuperview()
        blurView?.removeFromSuperview()
        self.newDeckView = nil

        let f  = view.frame
        let ht = NewDeckViewSimple.height()
        let dy = statusHeight + headerHeight + 40
        
        let v = UIView()
        v.frame = UIScreen.main.bounds
        v.backgroundColor = Color.black
        v.alpha = 0.0
        view.addSubview(v)
        let g1 = UITapGestureRecognizer(target: self, action:  #selector(onTapOnBlurView))
        v.addGestureRecognizer(g1)
        self.blurView = v

        let card = NewDeckViewSimple()
        card.view.frame = CGRect(x: 10, y: f.height, width: f.width-20, height: ht)
        card.config( from: self.club )
        card.delegate = self
        card.view.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 15)
        view.addSubview(card.view)
        view.bringSubviewToFront(card.view)
        self.newDeckView = card
        func fn(){
            self.newDeckView?.view.frame = CGRect(x: 10, y: dy, width: f.width-20, height: ht)
            self.blurView?.alpha = 1.0
        }
        runAnimation( with: fn, for: 0.25 ){ return }
        
    }
    
    
    private func hideNewDeck(){
        let f = view.frame
        func fn(){
            self.newDeckView?.view.frame = CGRect(x: 10, y: f.height, width: f.width-20, height: f.height-60)
        }
        runAnimation( with: fn, for: 0.25 ){
            self.newDeckView?.view.removeFromSuperview()
            self.newDeckView = nil
            self.blurView?.removeFromSuperview()
            self.blurView = nil
        }
    }
}



//MARK:- NewDeckView delegate

extension CardDirectoryController : NewDeckViewDelegate {

    func onDismissNewDeckView() {
        hideNewDeck()
    }
    
    func onCreateNewDeck(with name: String, color: UIColor, image: UIImage? ) {

        placeIndicator()
        
        let id = FlashCardDeck.create(name: name, tag: [], from: self.club, color: color, image: image)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
            
            guard let self = self else { return }
            self.hideNewDeck()
            
            if let deck = FlashCardCache.shared.decks[id] {

                self.hideIndicator()
                self.delegate?.onHandleTapDeck(on: deck)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                    self?.refresh()
                }
                
             } else {
                 ToastSuccess(title: "Oh no!", body: "An error occured")
                 self.hideIndicator()
             }
         }
        
    }

    func placeIndicator(){
        
        if self.dotView != nil { return }
            
        let f = view.frame
        let R = CGFloat(100)

        // parent view
        let pv = AwaitWidget(frame: CGRect(x: (f.width-R)/2, y: (f.height-R)/2, width: R, height: R))
        let _ = pv.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 10)
        pv.config( R: R, with: "Syncing")
        pv.backgroundColor = Color.primary_transparent_A
        view.addSubview(pv)
        self.dotView = pv

        //max duration is six seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0 ) { [weak self] in
            self?.hideIndicator()
        }
        
    }
    
    func hideIndicator(){
        dotView?.stop()
        func hide() { self.dotView?.alpha = 0.0 }
        runAnimation( with: hide, for: 0.25 ){
            self.dotView?.removeFromSuperview()
            self.dotView = nil
        }
    }
    
}


//MARK:- table


extension CardDirectoryController: UITableViewDataSource, UITableViewDelegate {
    
    private func layout(){
        
        let f = view.frame
        var dy = statusHeight
        let rect = CGRect(x:0,y:0,width:f.width,height:headerHeight)
        let header = AppHeader(frame: rect)
        header.config( showSideButtons: false, title: "Collections", small: true )
        view.addSubview(header)
        header.backgroundColor = UIColor.clear
        self.header = header

        dy += headerHeight

        let ht = f.height - statusHeight
        let table = UITableView(frame:CGRect(x:0,y:statusHeight,width:f.width,height:ht))
        self.view.addSubview(table)
        self.tableView = table
            
        // register cells
        tableView?.register(PadCell.self , forCellReuseIdentifier: PadCell.identifier )
        tableView?.register(HeaderH1Cell.self, forCellReuseIdentifier: HeaderH1Cell.identifier )
        tableView?.register(HeaderH2Cell.self, forCellReuseIdentifier: HeaderH2Cell.identifier )
        tableView?.register(CardDirectoryCell.self, forCellReuseIdentifier: CardDirectoryCell.identifier )
        

        // set delegates and style
        self.tableView?.delegate   = self
        self.tableView?.dataSource = self
        self.tableView?.showsVerticalScrollIndicator = false
        self.tableView?.separatorStyle = .none
        tableView?.backgroundColor = UIColor.clear
        
        // PTR
        if #available(iOS 10.0, *) {
            tableView?.refreshControl = refreshControl
        } else {
            tableView?.addSubview(refreshControl)
        }
        
        refreshControl.addTarget(self, action: #selector(ptr(_:)), for: .valueChanged)
        refreshControl.alpha = 0.0
        
        // button
        let wd = f.width/3
        let b2 = TinderTextButton()
        b2.frame = CGRect(x:(f.width-wd)/2,y: f.height-buttonHeight-20, width:wd,height:buttonHeight)
        b2.config(with: "New collection", color: Color.primary, font: UIFont(name: FontName.bold, size: AppFontSize.footerBold))
        b2.addTarget(self, action: #selector(handleTapAdd), for: .touchUpInside)
        b2.backgroundColor = Color.redDark
        view.addSubview(b2)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let (kind,_) = dataSource[indexPath.row]
        
        switch kind {
        case .pad:
            return 10
        case .term_pad:
            return computeTabBarHeight() + buttonHeight
        case .headerA:
            return AppFontSize.body+20
        case .headerB:
            return AppFontSize.body+20
        case .headerC:
            return AppFontSize.body+20
        case .cardRow:
            let f = view.frame
            let wd = (f.width - 2*15 - 10)/2
            return wd + CardDirectoryCell.textHeight
        }
    }
   
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        let ( kind, cards ) = dataSource[row]
        
        switch kind {
        
        case .pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: UIColor.clear)
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor.clear
            return cell
            
        case .term_pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: UIColor.clear)
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor.clear
            return cell
            
        case .headerA:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "Only visible to this cohort", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor.clear
            return cell

        case .headerB:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "Tagged by cohort", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor.clear
            return cell

        case .headerC:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "Explore", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor.clear
            return cell
            
        case .cardRow:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CardDirectoryCell", for: indexPath) as! CardDirectoryCell
            cell.config( with: cards )
            cell.selectionStyle = .none
            cell.delegate = self
            cell.backgroundColor = UIColor.clear
            return cell
        }
    }

}


private func to2DArray( _ reduced: [FlashCardDeck] ) -> [[FlashCardDeck]] {

    var patternArray : [[Int]] = []
    var num : Int = Int(reduced.count/2) + 1
    
    while num > 0 {
        patternArray.append([0,0])
        num -= 1
    }
    
    let res = overlay( patternArray, values: reduced )
    let sm = res.filter{ $0.count > 0 }
    return sm
}

