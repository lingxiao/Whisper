//
//  PlayListController.swift
//  byte
//
//  Created by Xiao Ling on 12/29/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


//MARK:- datatypes

protocol PlayListControllerDelegate {
    func startPodPlayingState( _ then: @escaping(Bool) -> Void )
}

enum PlayListCellKind {
    case pad
    case hero
    case song
}

typealias PlayListData = [(PlayListCellKind,PodItem?)]

/*
 @Use: renders my groups
*/
class PlayListController: UIViewController {

    // style
    var headerHeight: CGFloat = 80
    var statusHeight: CGFloat = 10.0

    // databasource + delegate
    var club: Club?
    var room: Room?
    var dataSource: PlayListData = []

    // pull to refresh
    var header: PlayListHeader?
    var tableView: UITableView?
    var refreshControl = UIRefreshControl()
    
    var delegate: PlayListControllerDelegate?
    
    override func viewDidLoad() {

        super.viewDidLoad()
        addGestureResponders()
        view.backgroundColor = Color.primary
        
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
        self.room = room
        layoutHeader()
        /*layoutHeaderB()
        if let header = self.header {
            tableView?.tableHeaderView = header
        }*/
        layoutTable()
        refresh()
    }
    
    
    func refresh(){

        guard let club = club else { return }
        guard let pl = club.getCurrentPlayList() else { return }

        let songs : PlayListData = Array(pl.pods.values).sorted{ $0.order < $1.order }.map{ (.song, $0) }
        var res : PlayListData = [(.pad,nil),(.hero,nil), (.pad,nil)]
        
        res.append(contentsOf: songs )
        self.dataSource = res
        tableView?.reloadData()

    }
}


//MARK:- events

extension PlayListController : SongCellDelegate, AppHeaderDelegate, PlayListHeroDelegate {

    func onSearch() {
        ToastSuccess(title: "Coming soon!", body: "")
    }
    
    func onPlay() {

        guard let club = club else { return }
        guard let room = self.room else { return }
        guard let mem = room.getMyRecord() else { return }
        
        if mem.state == .podding {
            playSong(for: club)
        } else {
            delegate?.startPodPlayingState(){ b in self.playSong(for:club) }
        }
        
    }
    
    private func playSong(for club: Club){

        if club.podIsPlaying(){
            club.pauseCurrentPod()
        } else {
            club.playCurrentPod()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
            self?.refresh()
        }
    }
    
    func handleTapSong(pod: PodItem?) {
        
        guard let pod = pod else { return }
        guard let club = self.club else { return }
        guard let room = self.room else { return }
        guard let mem = room.getMyRecord() else { return }

        if mem.state == .podding {
                
            club.playSelected(pod: pod)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                self?.refresh()
            }
            
        } else {
                
            delegate?.startPodPlayingState(){ b in
                club.playSelected(pod: pod)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                    self?.refresh()
                }
            }
        }
    }
    
    
    func handleTapSetting(pod: PodItem?) {
        return
    }
    
    
    func onHandleDismiss() {
        AuthDelegate.shared.home?.navigationController?.popToRootViewController(animated: true)
    }
    
}



//MARK:- view

extension PlayListController : UITableViewDataSource, UITableViewDelegate  {
    
    func layoutHeader(){
        let f = view.frame
        let h = AppHeader(frame: CGRect( x: 0, y: statusHeight, width: f.width, height: headerHeight ))
        h.config( showSideButtons: true, left: "", right: "xmark", title: "Room playlist", mode: .light )
        h.delegate = self
        self.view.addSubview(h)
        self.view.bringSubviewToFront(h)
    }
    

    func layoutHeaderB() {
        let f = view.frame
        let rect = CGRect(x:0,y:statusHeight,width:f.width,height:f.width*2/3)
        let header = PlayListHeader(frame: rect)
        header.config(with: self.club)
        view.addSubview(header)
        self.header = header
    }
    
    func layoutTable(){
        
        let f   = view.frame
        let dy  = statusHeight + headerHeight
        let ht  =  f.height - dy
        let table: UITableView = UITableView(frame: CGRect(x:0,y:dy,width:f.width,height:ht))
        table.backgroundColor = Color.primary

        // register cells
        table.register(PadCell.self  , forCellReuseIdentifier: PadCell.identifier )
        table.register(SongCell.self , forCellReuseIdentifier: SongCell.identifier)
        table.register(PlayListHero.self , forCellReuseIdentifier: PlayListHero.identifier)
        
        // mount
        self.tableView = table
        self.view.addSubview(table)
        
        // set delegates and style
        self.tableView?.delegate   = self
        self.tableView?.dataSource = self
        self.tableView?.showsVerticalScrollIndicator = false
        self.tableView?.backgroundColor = UIColor.clear
        self.tableView?.separatorStyle = .none
        
        // PTR
        if #available(iOS 10.0, *) {
            tableView?.refreshControl = refreshControl
        } else {
            tableView?.addSubview(refreshControl)
        }

        refreshControl.addTarget(self, action: #selector(ptr(_:)), for: .valueChanged)
        refreshControl.alpha = 0.0

    }
    
    @objc private func ptr(_ sender: Any) {
        refresh()
        self.refreshControl.endRefreshing()
    }
    
    /*func scrollViewDidScroll(_ scrollView: UIScrollView){
        if let headerView = self.tableView?.tableHeaderView as? ClubHeader {
            headerView.scrollViewDidScroll(scrollView: scrollView)
        }
    }*/
    
    // @Use: on select row, wave back to user to accept invite
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let (kind,_) = dataSource[indexPath.row]
        
        switch kind {
        case .pad:
            return indexPath.row == 0 ? 20 : 10
        case .hero:
            return 300
        case .song:
            return 80
        }
    }
        
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
        
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let (kind, data) = dataSource[indexPath.row]
        
        switch kind {
        
        case .pad:

            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: Color.primary)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell
            
        case .hero:
            
            var isPlaying: Bool = false
            if let club = self.club {
                isPlaying = club.podIsPlaying()
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlayListHero", for: indexPath) as! PlayListHero
            cell.config( with: self.club, isPlaying: isPlaying )
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            cell.delegate = self
            return cell

        case .song:
            var playing: Bool = false
            if let club = self.club {
                if let pod = data {
                    if let curr = club.getCurrentPod() {
                        if curr == pod {
                            playing = curr.pod.isPlaying()
                        }
                    }
                }
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongCell
            cell.config( with: data, playing: playing )
            cell.backgroundColor = Color.primary
            cell.delegate = self
            return cell
        }
    }
    
}



//MARK:- gesture

extension PlayListController {
    
    func addGestureResponders(){
        
        let swipeRt = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRt.direction = .right
        self.view.addGestureRecognizer(swipeRt)
    }
    
    // Swipe gesture
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {

            switch swipeGesture.direction {
            
            case .right:
                onHandleDismiss()
            default:
                break
            }
        }
    }

    
}
