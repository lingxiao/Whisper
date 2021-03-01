//
//  RoomGridController.swift
//  byte
//
//  Created by Xiao Ling on 12/22/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit


protocol RoomGridControllerDelegate {
    func onTapUser( at user: User? ) -> Void
    func onTapHeader( for club: Club?, at room: Room? ) -> Void
    func onHandleTapWidget(on widget: ClubWidgets? ) -> Void
    func didRefreshGrid() -> Void
}

enum RoomGridCellKind {
    case pad
    case padTail
    case hero
    case podRef
    case headerA
    case headerB
    case headerC
    case headerD
    case headerE
    case speakers
    case listeners
    
    case morePodders
}

typealias RoomGridData = [(RoomGridCellKind,[RoomMember])]

class RoomGridController : UIViewController {
    
    // data
    var dataSource:RoomGridData = [(.pad,[])]
    
    //style
    var headerHeight: CGFloat = 70
    var statusHeight : CGFloat = 10.0

    // view
    var header: AudioRoomHeader?
    var tableView: UITableView?
    let refreshControl = UIRefreshControl()

    // delegate + ID
    var room: Room?
    var club: Club?
    var delegate: RoomGridControllerDelegate?
    var parentVC: AudioRoomController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Color.primary
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
        /*let refreshImage = UIImageView()
        refreshImage.image = UIImage(named: "")
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.tintColor = UIColor.clear
        refreshControl.addSubview(refreshImage)
        */
    }
    
    //MARK:- API
    
    func config( with room : Room?, club: Club? ){
        self.room = room
        self.club = club
        layoutHeader()
        layoutTable()
        if let header = self.header {
            tableView?.tableHeaderView = header
        }
        if let room = room {
            if room.iamHere() {
                refresh()
            } else {
                loadHeaderOnly()
            }
        } else {
            loadHeaderOnly()
        }
    }
        

    // insert user if there's less than 1000 users
    func insert( _ mem: RoomMember? ){

        guard let mem = mem else { return }
        var members : [RoomMember] = toListOfUsers(self.dataSource)

        if members.contains(mem) == false && (members.count < 10000 || mem.state != .speaking) {
            members.append(mem)
            reloadGrid(with: members)
        }
    }
    
    // remove user
    func remove( _ mem: RoomMember?){
        guard let mem = mem else { return }
        var members : [RoomMember] = toListOfUsers(self.dataSource)
        if members.contains(mem) {
            members = members.filter{ $0 != mem }
            reloadGrid(with: members)
        }
    }
    
    
    // refresh table
    func refresh(){
        guard let room = room else { return }
        reloadGrid(with: room.getAttendingMembers())
    }
    
    func reloadSong(){
        if dataSource.count >= 4 {
            let indexPath = IndexPath(item: 3, section: 0)
            if let _ = tableView?.dequeueReusableCell(withIdentifier: PodHeaderCell.identifier, for: indexPath) as? PodHeaderCell {
                tableView?.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    func loadHeaderOnly(){
        if let room = self.room {
            if room.isRoot {
                self.dataSource = [(.pad, []), (.hero,[]),(.pad,[])]
            } else {
                self.dataSource = [(.pad, [])]
            }
        } else {
            self.dataSource = [(.pad, [])]
        }
        tableView?.reloadData()
    }
    
    
    // build dataSource for table according to speaker attributes
    private func reloadGrid( with unordered_members: [RoomMember] ){
        
        guard let room = room else { return }
        
        let members = GLOBAL_DEMO
            ? getTwentyMembers() //yieldDummyRoomMembers( for: 100 )
            : Array(unordered_members.sorted{ $0.joinedTime < $1.joinedTime })
                
        var data : RoomGridData = []
        
        if room.isRoot {
            data = [(.pad, []), (.hero,[]),(.pad,[])]
        } else {
            data = [(.pad, [])]
        }

        let podding : [RoomMember]  = members.filter{ $0.state == .podding    }
        let spkrs   : [RoomMember]  = members.filter{ $0.state == .speaking   }
        let raisers : [RoomMember]  = members.filter{ $0.state == .raisedHand }
        let lisnrs  : [RoomMember]  = members.filter{ $0.state == .listening  }
        
        // add podding
        if podding.count > 0 {

            data.append( contentsOf: [ (.headerD,[]), (.pad,[])])
                        
            let xss = room.isRoot ? to4DArray( podding ) : to3DArray(podding)
            
            if xss.count > 3 {
                let prefix = xss.prefix(3)
                data.append( contentsOf: prefix.map{ (.listeners,$0) } )
                data.append( ( .morePodders, []) )
            } else {
                data.append( contentsOf: xss.map{ (.listeners,$0) } )
            }
        }
        
        // add speakers
        if spkrs.count > 0 {
            data.append( contentsOf: [ (.headerA,[]), (.pad,[])])
            //let res = [spkrs[0],spkrs[0],spkrs[0],spkrs[0],spkrs[0],spkrs[0],spkrs[0],spkrs[0]]
            let xss = room.isRoot ? to4DArray( spkrs ) : to3DArray( spkrs )
            data.append( contentsOf: xss.map{ (.speakers,$0) } )
        }

        // add hand raisers
        if raisers.count > 0 {
            data.append( contentsOf: [(.headerB,[]), (.pad,[])])
            let xss = room.isRoot ? to4DArray( raisers ) : to3DArray( raisers )
            data.append( contentsOf: xss.map{ (.listeners,$0) } )
        }

        // add listeners
        if lisnrs.count > 0 {
            data.append( contentsOf: [(.headerC,[]), (.pad,[])])
            let xss = room.isRoot ? to4DArray(lisnrs) : to3DArray(lisnrs)
            data.append( contentsOf: xss.map{ (.listeners,$0) } )
        }
        
        // add buttom padding
        data.append((.padTail,[]))
        
        self.dataSource = data
        tableView?.reloadData()
        
        delegate?.didRefreshGrid()

    }
}

//MARK:- events

extension RoomGridController : PodHeaderCellDelegate, RoomHeaderCellDelegate, SpeakerRowDelegate, HeaderH2CellDelegate {

    func handleTapPodHeader( on club: Club?, from room: Room?, with pod: PodItem? ){
        return
    }

    func onTapSpeakerRowUser( at user: User? ){
        delegate?.onTapUser(at: user)
    }
    
    func handleTapRoomHeader( on club: Club?, from room: Room?, with user: User? ){
        delegate?.onTapHeader( for: club, at: room )
    }
    
    func onTapWidget( at widget: ClubWidgets? ){
        delegate?.onHandleTapWidget(on: widget)
    }
    
    func onSkipR( from pod: PodItem? ){
        //delegate?.onSkipR(from:pod)
    }
    
    func didTapH2Btn(){
        //delegate?.onTapShowPodders()
    }
}


//MARK:- table

extension RoomGridController: UITableViewDataSource, UITableViewDelegate {
    
    func layoutHeader(){
        let f = view.frame
        let v = AudioRoomHeader(frame: CGRect( x: 0, y: statusHeight, width: f.width, height: headerHeight ))
        v.config(with: self.club, room:self.room)
        v.delegate = self.parentVC
        view.addSubview(v)
        self.header = v
    }

    func layoutTable(){
        
        let f = view.frame
        let table = UITableView(frame:CGRect(x:0,y:0,width:f.width,height:f.height))
        self.view.addSubview(table)
        self.tableView = table
            
        // register cells
        tableView?.register(SpeakerRow.self, forCellReuseIdentifier: SpeakerRow.identifier)
        tableView?.register(PadCell.self , forCellReuseIdentifier: PadCell.identifier )
        tableView?.register(HeaderH1Cell.self, forCellReuseIdentifier: HeaderH1Cell.identifier )
        tableView?.register(HeaderH2Cell.self, forCellReuseIdentifier: HeaderH2Cell.identifier )
        tableView?.register(RoomHeaderCell.self, forCellReuseIdentifier: RoomHeaderCell.identifier )
        tableView?.register(PodHeaderCell.self, forCellReuseIdentifier: PodHeaderCell.identifier )

        // set delegates and style
        self.tableView?.delegate   = self
        self.tableView?.dataSource = self
        self.tableView?.showsVerticalScrollIndicator = false
        self.tableView?.separatorStyle = .none
        tableView?.backgroundColor =  Color.primary
        
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

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let (kind,_) = dataSource[indexPath.row]
        
        var num : Int = 4
        if let room = self.room {
            if room.isRoot == false {
                num = 3
            }
        }
        
        switch kind {
        case .pad:
            return 10
        case .padTail:
            return 50
        case .hero:
            return 80.0
        case .podRef:
            return 120.0
        case .speakers:
            return SpeakerRow.height(num:num) + 10
        case .listeners:
            return SpeakerRow.height(num:num) + 10
        case .headerA:
            return AppFontSize.body+20
        case .headerB:
            return AppFontSize.body+20
        case .headerC:
            return AppFontSize.body+20
        case .headerD:
            return AppFontSize.body+20
        case .headerE:
            return AppFontSize.body+20
        case .morePodders:
            return AppFontSize.footerLight+20
        }
    }
   
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        let ( kind, users ) = dataSource[row]
        
        switch kind {

        case .pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: Color.primary)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell
            
        case .padTail:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: Color.primary)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell
            
        case .headerA:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "Talking", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell

        case .headerB:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "Raised hand", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell
            
        case .headerC:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "Listening", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell

        case .headerD:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "Browsing", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell

        case .headerE:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "Widgets", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell
            
        case .speakers:
            let cell  = tableView.dequeueReusableCell(withIdentifier: SpeakerRow.identifier, for: indexPath) as! SpeakerRow
            cell.selectionStyle = .none
            cell.config( with: users, at: self.room )
            cell.delegate = self
            return cell

        case .listeners:
            let cell  = tableView.dequeueReusableCell(withIdentifier: SpeakerRow.identifier, for: indexPath) as! SpeakerRow
            cell.selectionStyle = .none
            cell.config( with: users, at: self.room )
            cell.delegate = self
            return cell
            
        case .hero:
            let cell  = tableView.dequeueReusableCell(withIdentifier: RoomHeaderCell.identifier, for: indexPath) as! RoomHeaderCell
            cell.selectionStyle = .none
            cell.config( with: self.club, room: self.room, showImage: false )
            cell.delegate = self
            return cell

        case .podRef:
            let cell  = tableView.dequeueReusableCell(withIdentifier: PodHeaderCell.identifier, for: indexPath) as! PodHeaderCell
            cell.selectionStyle = .none
            cell.config( with: self.club, room: self.room, pod: self.club?.getCurrentPod() )
            cell.delegate = self
            return cell
            
        case .morePodders:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH2Cell", for: indexPath) as! HeaderH2Cell
            cell.config(with: "See all")
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            cell.delegate = self
            return cell

        }
    }

}



private func toListOfUsers( _ data: RoomGridData ) -> [RoomMember] {
    var res : [RoomMember] = []
    for (k,xs) in data {
        switch k {
        case .speakers:
            res.append(contentsOf: xs)
        case .listeners:
            res.append(contentsOf: xs)
        default:
            break;
        }
    }
    return res
}


private func to4DArray( _ reduced: [RoomMember] ) -> [[RoomMember]] {

    var patternArray : [[Int]] = []
    var num : Int = Int(reduced.count/4) + 1
    
    while num > 0 {
        patternArray.append([0,0,0,0])
        num -= 1
    }
    
    let res = overlay( patternArray, values: reduced )
    return res
}



private func to3DArray( _ reduced: [RoomMember] ) -> [[RoomMember]] {

    var patternArray : [[Int]] = []
    var num : Int = Int(reduced.count/3) + 1
    
    while num > 0 {
        patternArray.append([0,0,0])
        num -= 1
    }
    
    let res = overlay( patternArray, values: reduced )
    return res
}
