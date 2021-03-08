//
//  EditClub.swift
//  byte
//
//  Created by Xiao Ling on 12/24/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit



protocol EditClubProtocol {
    func willExitEditClub() -> Void
}

let EDIT_EXPLAIN = "If you believe your number has been compromised, you can request a new number by tapping the scramble button. Existing members can still access the space, but prospective users can no longer find you with the old number. Press and hold for three seconds to scamble."
let EDIT_DELETE = "Delete this channel. Everyone will be booted from this live session immediately, this action is not reversible. Press and hold for three seconds to delete."
let EDIT_OPEN  = "Make this channel visible so that people can discover it on the home page. Press and hold for three seconds to confirm."
let EDIT_CLOSE = "Make this channel invisible so that only members can see it. Press and hold for three seconds to confirm."


enum EditClubCellKind {
    case pad
    case bot_pad
    case headerA
    case headerB
    case headerC
    case headerD
    case editName
    case leaveClub
    case editPhoto
    case editNumber
    case lockGroup
    case deleteClub
    case user
}

typealias EditClubData = [ (EditClubCellKind, User?)  ]

class EditClubController: UIViewController {
    
    // data
    var club: Club?
    var room: Room?
    var org : OrgModel?
    var delegate: EditClubProtocol?
    var dataSource : EditClubData = []

    // style
    var textHt: CGFloat = 40
    var headerHeight: CGFloat = 70
    var statusHeight : CGFloat = 10.0

    // views
    var header: PlayListHeader?
    var tableView: UITableView?
    let refreshControl = UIRefreshControl()
    var changeNumberBtn: TinderTextButton?
    var addBtn: TinderTextButton?
    
    // modal
    var blurView: UIView?
    var phoneNumberView: PhoneNumberView?


    
    //image
    let imagePicker = UIImagePickerController()
    var newlyPickedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Color.primary
        
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
        
        addGestureResponders()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        let _ = self.tappable(with: #selector(didTap))
        
    }
    
    
    func config( with club: Club?, room: Room?, org: OrgModel? =  nil ){

        self.club = club
        self.room = room
        self.org  = org
        
        layoutHeaderA()
        if let club = club {
            layoutHeaderB()
        }
        layoutTable()
        if let header = self.header {
            tableView?.tableHeaderView = header
        }
        listenClubPagePTR(on: self, for: #selector(goReloadPage))
        refresh()
    }
    
    func refresh(){
        
        if let club = self.club {
                
            var res : EditClubData = []

            if club.iamOwner {
                if club.type == .home {
                    res = [.pad,.pad,.headerA,.editPhoto].map{ ($0,nil)}
                } else {
                    res = [.pad,.pad,.headerA,.editName,.editPhoto,.deleteClub].map{ ($0,nil)}
                }
            } else {
                res = [.pad,.pad, .headerA,.leaveClub ].map{ ($0,nil)}
            }
            
            self.dataSource = res
            tableView?.reloadData()
            
        } else if let org = self.org {
            
            var res : EditClubData = []
        
            if org.creatorID == UserAuthed.shared.uuid {
                res.append( (.headerA, nil) )
                res.append( (.editNumber, nil) )
            }
            
            let head : EditClubData = [(.user,org.creator)]
            let tail : EditClubData = org.getRelevantUsers( excludeCreator: true ).map{ (.user,$0) }
            
            if let _ = org.creator {
                res.append( (.headerC,nil) )
                res.append( contentsOf: head)
            }
            
            if tail.count > 0 {
                res.append( (.headerD,nil) )
                res.append( contentsOf:  tail)
                res.append( (.bot_pad,nil) )
            }
            
            self.dataSource = res
            tableView?.reloadData()
        }
    }
        
    
    @objc func goReloadPage(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
            self?.refresh()
        }
    }

    
    @objc func didTap(){
        SwiftEntryKit.dismiss()
    }
}

//MARK:- invite user

extension EditClubController: InviteUserProtocol {
    
    @objc func handleTapJoin(_ button: TinderButton ){

        guard let club = club else { return }
        guard let org = club.getOrg() else { return }
        if club.iamAdmin() == false { return }

        var users : [User] = org.getRelevantUsers()
        users = users.filter{ club.getMembers().contains($0) == false }

        let v = InviteUserController()
        v.view.frame = UIScreen.main.bounds
        v.config(data: users, title: "Add members")
        v.delegate = self
        AuthDelegate.shared.home?.navigationController?.pushViewController(v, animated: true)
        
    }

    // @use: add usrs to club
    // force add so that even if club is locked, i can still add
    func didSelect(users: [User]) -> (Bool, String) {
        
        if users.count == 0 {
            return (false, "Please select at least one person")
        } else {
            for user in users {
                club?.join(_HARD_UID: user.uuid, with: .levelB, force: true){ return }
            }
            ToastSuccess(title: "Done!", body: "You should see the updates in a second")
            postClubPagePTR()
            return (true, "")
        }
    }
    
}



//MARK:- events

extension EditClubController : SettingCellProtocol, InputStringModalDelegate  {

    func handleConsent(from domain: Int){
        
        SwiftEntryKit.dismiss()
        guard let club = club else { return }

        switch domain {
        case 0:
            let org = ClubList.shared.fetchOrg(for:club)
            org?.scrambleBackdoorCode(){ _ in return }
            ToastSuccess(title: "Done!", body: "You have a new number")
        case 1:
            let tit = "Are you sure you want to delete this channel"
            let bod = "This action cannot be reversed"
            let optionMenu = UIAlertController(title: tit, message: bod, preferredStyle: .actionSheet)
            let saveAction   = UIAlertAction(title: "Delete", style: .default, handler: self.onHandleDelete)
            let cancelAction = UIAlertAction(title: "Cancel"   , style: .cancel )
            optionMenu.addAction(saveAction)
            optionMenu.addAction(cancelAction)
            self.present(optionMenu, animated: true, completion: nil)
        case 2:
            let str = club.locked ? "Unlocked" : "Locked"
            ToastSuccess(title: str, body: "")
            club.toggleLock()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                self?.refresh()
            }
        default:
            break;
        }
        
        postClubPagePTR()
        postRefreshClubPage( at: self.club?.uuid ?? "")

    }
    

    // delete club and go back to home controller
    private func onHandleDelete(_ x: UIAlertAction) {
        ToastSuccess(title: "Removed", body: "")
        if let room = club?.getRootRoom() {
            room.shutDown { return }
        }
        club?.deleteClub()
        postRefreshClubPage( at: self.club?.uuid ?? "")
        AuthDelegate.shared.home?.navigationController?.popToRootViewController(animated: true)
    }

    func handleTapName() {
        let f = view.frame
        let ratio = InputStringModal.height()/f.height
        let attributes = centerToastFactory(ratio: ratio, displayDuration: 100000)
        let modal = InputStringModal()
        modal.delegate = self
        modal.config( width: f.width-20, h1: "Change name", h2: "" )
        SwiftEntryKit.display(entry: modal, using: attributes)
    }
    
    
    func handleTapPhoto() {
        showImagePicker()
    }
    
    func handleTapNumber() {

        heavyImpact()
        guard let club = self.org?.getHomeClub() else {
            return ToastSuccess(title: "", body: "No data found")
        }
        
        self.phoneNumberView?.removeFromSuperview()
        self.phoneNumberView = nil
        
        let v = UIView()
        v.frame = UIScreen.main.bounds
        v.backgroundColor = Color.black
        v.alpha = 0.0
        view.addSubview(v)
        let g1 = UITapGestureRecognizer(target: self, action:  #selector(onTapOnBlurViewFromPhoneNumberView))
        v.addGestureRecognizer(g1)
        self.blurView = v
        
        let f = view.frame
        let ht = PhoneNumberView.Height(  with: club, width: f.width-20, short: false )
        let dy = (f.height - ht)/2
        let card = PhoneNumberView(frame:CGRect(x: 10, y: f.height, width: f.width-20, height: ht))
        card.config(with: club)
        card.delegate = self
        card.roundCorners(corners: [.topLeft,.topRight,.bottomLeft,.bottomRight], radius: 25)
        view.addSubview(card)
        view.bringSubviewToFront(card)
        self.phoneNumberView = card
        
        func fn(){
            self.phoneNumberView?.frame = CGRect(x: 10, y: dy, width: f.width-20, height: ht)
            self.blurView?.alpha = 1.0
        }
        runAnimation( with: fn, for: 0.25 ){ return }

    }
    
    
    func handleTapDelete() {
        self.handleConsent(from: 1)
    }
    
    func handleTapLock() {

        guard let club = club else { return }
        
        if club.locked {
            ToastExplain(title: "Unlock channel", body: EDIT_OPEN, btn: "Unlock"){
                self.handleConsent(from: 2)
            }
        } else {
            ToastExplain(title: "Lock channel", body: EDIT_CLOSE, btn: "Lock"){
                self.handleConsent(from: 2)
            }
        }
    }
    
    func handleLeaveGroup(){

        guard let club = club else { return }
        
        let bod = "Are you sure you want to leave this channel"
        let optionMenu = UIAlertController(title: "Leave this channel", message: bod, preferredStyle: .actionSheet)
            
        let deleteAction = UIAlertAction(title: "Yes", style: .default, handler: { a in

            club.getRootRoom()?.leave()

            if let me = UserList.shared.yieldMyself() {
                club.remove(me)
                postRefreshClubPage(at:self.club?.uuid ?? "")
                ToastSuccess(title: "Done!", body: "You have left this channel")
                AuthDelegate.shared.home?.navigationController?.popToRootViewController(animated: true)
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel )
            
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)

    }
    
    func handleInputString(_ str: String ){
        SwiftEntryKit.dismiss()
        if str == "" { return }
        club?.changeName(to: str)
        postClubPagePTR()
        postRefreshClubPage( at: self.club?.uuid ?? "")
    }
}


extension EditClubController: PhoneNumberViewDelegate {

    func onDismissPhoneNumberView() {
        let f = view.frame
        func fn(){ self.phoneNumberView?.frame = CGRect(x: 10, y: f.height, width: f.width-20, height: f.height-60) }
        runAnimation( with: fn, for: 0.25 ){
            self.phoneNumberView?.removeFromSuperview()
            self.phoneNumberView = nil
            self.blurView?.removeFromSuperview()
            self.blurView = nil
        }
    }
    

    @objc func onTapOnBlurViewFromPhoneNumberView(sender : UITapGestureRecognizer){
        onDismissPhoneNumberView()
    }
    
}


//MARK: - user row events

extension EditClubController: UserRowCellProtocol {
    
    // follow user
    func handleBtn(on user: User?) {
        guard let user = user else { return }
        heavyImpact()
        if UserAuthed.shared.iAmFollowing(at: user.uuid) {
            UserAuthed.shared.unfollow(user)
        } else {
            UserAuthed.shared.follow(user)
        }
    }

    // go to profile or if i am admin: set permissions
    func handleTap(on user: User?) {
        
        mediumImpact()
        guard let user = user else { return }
        goToProfile(user)

        /*guard let org = org else { return }

        if user.isMe() {
            
            heavyImpact()
            
        } else if org.iamOwner {

            let f = view.frame
            let ratio = ClubPageModal.height()/f.height
            let attributes = centerToastFactory(ratio: ratio, displayDuration: 100000)
            let modal = ClubPageModal()
            modal.delegate = self
            modal.config( with: club, for: user, width: f.width-20)
            SwiftEntryKit.display(entry: modal, using: attributes)
     
        } else {
            
            goToProfile(user)
        }*/
        
    }
    
    // remove user
    func confirmRemoval(for user: User){
        let bod = "Remove \(user.get_H1())?"
        let optionMenu = UIAlertController(title: bod, message: "", preferredStyle: .actionSheet)
        let yesAction = UIAlertAction(title: "Yes" , style: .default, handler: {a in
            self.club?.remove(user)
            ToastSuccess(title: "Removed!", body: "You will see the updates in a few seconds")
            postClubPagePTR()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel )
        optionMenu.addAction(yesAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    private func goToProfile( _ user: User ){
        mediumImpact()
        let vc = ProfileController()
        vc.view.frame = UIScreen.main.bounds
        vc.config( with: user, isHome: false )
        AuthDelegate.shared.home?.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension EditClubController : ClubPageModalDelegate {

    func onHandleAdmin(with club: Club, for user: User) {
        SwiftEntryKit.dismiss()
        if club.iamOwner == false { return }
        club.setAsAdmin(at: user, admin: !club.isAdmin(user) )
        ToastSuccess(title: "Done!", body: "You'll see the update in a second")
        postClubPagePTR()
    }
    
    func onHandleRemove(with club: Club, for user: User) {
        SwiftEntryKit.dismiss()
        if club.iamOwner == false { return }
        self.confirmRemoval(for:user)
    }
    
    func onHandleNavToProfile(to user: User) {
        SwiftEntryKit.dismiss()
        goToProfile(user)
    }
    
}



//MARK:- image picker

extension EditClubController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func showImagePicker(){
        permitAVCapture(){(succ,msg) in
            if ( succ ){
                self.openImagePicker()
            } else {
                return ToastSuccess(title: "", body: "We do not have permission to open your files")
            }
        }
    }

    //@use: open picker for file only
    func openImagePicker(){
        DispatchQueue.main.async {
            self.imagePicker.allowsEditing = true
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }
    }


    // @use: reset image in the view, *then* save to db
    func imagePickerController(
         _ picker: UIImagePickerController
        , didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {

        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.newlyPickedImage = pickedImage
        } else if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.newlyPickedImage = pickedImage
        }


        dismiss(animated: true, completion: nil)
        saveImage()
        ToastSuccess(title: "", body: "Your picture has been saved!")
    }


    // @Use: save profile image
    func saveImage(){
        guard let image = self.newlyPickedImage else {
            return ToastSuccess(title: "", body: "Network error")
        }
        header?.imageView.image = newlyPickedImage
        self.club?.changeClubImage(to: image){ succ in
            if ( succ ){
                ToastSuccess(title:"", body:"Profile picture saved")
                postClubPagePTR()
                postRefreshClubPage(at:self.club?.uuid ?? "")
            } else {
                return ToastSuccess(title: "", body: "Network error")
            }
        }
    }

}


//MARK:- view

extension EditClubController {
    
    func layoutHeaderA() {
        let f = view.frame
        let rect = CGRect(x:0,y:statusHeight,width:f.width,height:headerHeight)
        let header = AppHeader(frame: rect)
        header.config(showSideButtons: true, left: "", right: "xmark", title: "Settings")
        header.delegate = self
        view.addSubview(header)
    }

    func layoutHeaderB() {
        let f = view.frame
        let rect = CGRect(x:0,y:statusHeight,width:f.width,height:f.width*2/3)
        let header = PlayListHeader(frame: rect)
        header.config(with: self.club)
        view.addSubview(header)
        self.header = header
    }
    
    func layoutBtn(){
        
        guard let club = self.club else { return }
        if club.iamAdmin() == false { return }
        let btn = TinderTextButton()
        let R : CGFloat = 40.0
        let f = view.frame
        btn.frame = CGRect(x: (f.width-3*R)/2, y: f.height - R - 24, width: 3*R, height: R)
        btn.config(with: "Quick add", color: Color.primary, font:  UIFont(name: FontName.bold, size: AppFontSize.footerBold+2))
        btn.backgroundColor = Color.redDark
        btn.addTarget(self, action: #selector(handleTapJoin), for: .touchUpInside)
        view.addSubview(btn)
        self.addBtn = btn
    }
    

    
    func layoutTable(){
        
        let f = view.frame
        let dy = statusHeight + headerHeight
        let table = UITableView(frame:CGRect(x:0,y:dy,width:f.width,height:f.height-dy))
        self.view.addSubview(table)
        self.tableView = table
            
        // register cells
        tableView?.register(SpeakerRow.self    , forCellReuseIdentifier: SpeakerRow.identifier)
        tableView?.register(PadCell.self       , forCellReuseIdentifier: PadCell.identifier )
        tableView?.register(HeaderH1Cell.self  , forCellReuseIdentifier: HeaderH1Cell.identifier )
        tableView?.register(SettingCell.self   , forCellReuseIdentifier: SettingCell.identifier )
        tableView?.register(UserRowCell.self   , forCellReuseIdentifier: UserRowCell.identifier )

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
}

//MARK:- table


extension EditClubController :  UITableViewDataSource, UITableViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView){
        if let headerView = self.tableView?.tableHeaderView as? PlayListHeader {
            headerView.scrollViewDidScroll(scrollView: scrollView)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let (kind,_) = dataSource[indexPath.row]
        switch kind {
        case .pad:
            return 10
        case .bot_pad:
            return computeTabBarHeight() + 20
        case .headerA:
            return AppFontSize.body+20
        case .headerB:
            return AppFontSize.body+20
        case .headerC:
            return AppFontSize.body+20
        case .headerD:
            return AppFontSize.body+20
        case .user:
            return 60
        default:
            return AppFontSize.footerBold + 40
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        let (kind,user) = dataSource[row]
        
        switch kind {

        case .pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: Color.primary)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell
        case .bot_pad:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PadCell", for: indexPath) as! PadCell
            cell.config(color: Color.primary)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell
        case .headerA:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "GENERAL", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell
        case .headerB:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "PRIVACY", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell
        case .headerC:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "ADMIN", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell
        case .headerD:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderH1Cell", for: indexPath) as! HeaderH1Cell
            cell.config(with: "MEMBERS", textColor: Color.grayPrimary, font: UIFont(name: FontName.bold, size: AppFontSize.footer)!)
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            return cell
        case .user:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserRowCell", for: indexPath) as! UserRowCell
            cell.config(with: user, button: true)
            cell.backgroundColor = UIColor.clear
            cell.delegate = self
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
            cell.config( with: kind, club: self.club )
            cell.selectionStyle = .none
            cell.backgroundColor = Color.primary
            cell.delegate = self
            return cell
        }
        
    }
   
    
}


//MARK:- navigation responder

extension EditClubController : AppHeaderDelegate {

    @objc func handleTapImage(_ sender: UITapGestureRecognizer? = nil) {
        //showImagePicker()
    }
    
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
            case .down:
                break;
            case .left:
                break;
            case .up:
                break;
            default:
                break
            }
        }
    }

    func onHandleDismiss() {
        postRefreshClubPage( at: self.club?.uuid ?? "")
        postClubPagePTR()
        delegate?.willExitEditClub()
        AuthDelegate.shared.home?.navigationController?.popViewController(animated: true)
    }

}
