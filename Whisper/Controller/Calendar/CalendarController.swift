//
//  CalendarController.swift
//  byte
//
//  Created by Xiao Ling on 2/13/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import SwiftEntryKit
import NVActivityIndicatorView
import EventKit
import EventKitUI



protocol CalendarControllerDelegate {
    func onHandleHideAnalyticsController( at vc: CalendarController )
}


enum CalendarControllerCellKind {
    case pad
    case bot_pad
    case item
    case headerA
    case headerB
    case headerC
}

typealias CalendarControllerDataSource =  [(CalendarControllerCellKind,WhisperEvent?)]

class CalendarController : UIViewController {
    
    var delegate: CalendarControllerDelegate?
    
    // data
    var club: Club?
    var room: Room?
    var org: OrgModel?
    var dataSource: CalendarControllerDataSource = []
    var eventStore : EKEventStore?
        
    // style
    var headerHeight: CGFloat = 70
    var statusHeight : CGFloat = 10.0
    var showHeader: Bool = true

    // view
    var awaitView: AwaitWidget?
    var header: AppHeader?
    var emptyLabel: UITextView?
    var tableView: UITableView?
    var refreshControl = UIRefreshControl()
    
    let bkColor = Color.white
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGestureResponders()
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
    }

    public func config( with org: OrgModel? ){
        self.org = org
        self.eventStore = EKEventStore()
        view.backgroundColor = bkColor
        layout()
        reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
            self?.reload()
        }
    }
    
    
    func reload(){

        var res : CalendarControllerDataSource = [(.pad,nil)]
        let raw = WhisperCalendar.shared.getEvents(for: self.org)

        let active = raw.filter{ $0.clubID != "" }
        let mine   = raw.filter{ active.contains($0) == false && $0.user.isMe() }
        let rest   = raw.filter{ active.contains($0) == false && $0.user.isMe() == false }
        
        var evts : CalendarControllerDataSource = []
        
        if active.count > 0 {
            evts.append((.headerA,nil))
            evts.append(contentsOf: active.map{ (.item,$0) })
        }

        if mine.count > 0 {
            evts.append((.headerB,nil))
            evts.append(contentsOf: mine.map{ (.item,$0) })
        }

        if rest.count > 0 {
            evts.append((.headerC,nil))
            evts.append(contentsOf: rest.map{ (.item,$0) })
        }
        
        res.append(contentsOf: evts)
        res.append((.bot_pad, nil))

        self.dataSource = res
        tableView?.reloadData()
        
        if raw.count == 0 {
            layoutEmpty()
        } else {
            emptyLabel?.removeFromSuperview()
        }
    }
    
}

//MARK:- cell events

extension CalendarController: CalendarCellDelegate {
    
    func onTapCell(from event: WhisperEvent?){

        // fetch the most recent event
        guard let event = event else { return }
        guard let evt = WhisperCalendar.shared.cached[event.ID] else { return }

        let optionMenu = UIAlertController(
            title: event.name,
            message: "Respond to event",
            preferredStyle: .actionSheet
        )
            
        if event.user.isMe() {
            
            // create new room from this event
            var a1 = UIAlertAction(title: "Start event now", style: .default, handler: {a in
                
                guard let org = self.org else {
                    return ToastSuccess(title: "Oh no!", body: "We can't start a room at this moment")
                }

                self.placeIndicator()
                Club.create(name: event.name, orgID: org.uuid, type: .ephemeral, locked:false ){ cid in
                
                    guard let cid = cid else {
                        self.hideIndicator()
                        return ToastSuccess(title: "Ops", body: "Network error")
                    }
                    
                    WhisperCalendar.shared.didStartEvent(at: event, in: cid)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                        guard let self = self else { return }
                        self.hideIndicator()
                        self.onHandleDismiss()
                        ClubList.shared.getClub(at: cid){ club in
                            postRefreshClubPage(at:"ALL")
                            if let home = AuthDelegate.shared.home as? HomeController {
                                home.showClub(at: club)
                            }
                        }
                    }
                }
            })
            
            if evt.clubID != "" {
                ClubList.shared.getClub(at: evt.clubID){ club in
                    guard let club = club else { return }
                    guard let room = club.getRootRoom() else { return }
                    if room.call_state == .ended { return }
                    a1 = UIAlertAction(title: "Join ongoing room", style: .default, handler: {a in
                        if let home = AuthDelegate.shared.home as? HomeController {
                            self.onHandleDismiss()
                            home.showClub(at: club)
                        }
                    })
                }
            }
            
            // cancel event
            let a2 = UIAlertAction(title: "Remove event", style: .default, handler: {a in
                WhisperCalendar.shared.remove(this: event)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                    self?.reload()
                }
            })
            let a3 = UIAlertAction(title: "Cancel", style: .cancel )
            optionMenu.addAction(a1)
            optionMenu.addAction(a2)
            optionMenu.addAction(a3)
            
        } else {
            
            var a1 = UIAlertAction(title: "RSVP", style: .default, handler: {a in
                self.onDidRSVp(from: event)
            })
            
            if (event.clubID != "") {
                ClubList.shared.getClub(at: evt.clubID){ club in
                    guard let club = club else { return }
                    guard let room = club.getRootRoom() else { return }
                    if room.call_state == .ended { return }
                    a1 = UIAlertAction(title: "Join ongoing room", style: .default, handler: {a in
                        if let home = AuthDelegate.shared.home as? HomeController {
                            self.onHandleDismiss()
                            home.showClub(at: club)
                        }
                    })
                }
            }
            let a2 = UIAlertAction(title: "Cancel", style: .cancel )
            optionMenu.addAction(a1)
            optionMenu.addAction(a2)
        }
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    // add self to alert, add event to calendar
    func onDidRSVp(from event: WhisperEvent?){

        guard let event = event else {
            return ToastSuccess(title: "Oh no!", body: "We cannot load this event at this moment")
        }

        WhisperCalendar.shared.rsvp(to: event)
        ToastSuccess(title: "You just rsvped", body: "")

        guard let eventStore = self.eventStore else { return }

        eventStore.requestAccess(to: EKEntityType.event) { (accessGranted, error) in
            if accessGranted{
                DispatchQueue.main.async {
                    self.goSaveToCalendar( event)
                }
            } else {
                return ToastSuccess(title: "We cannot access your calendar", body: "")
            }
        }
    }
    
    
    private func goSaveToCalendar( _ event: WhisperEvent ){

        guard let eventStore = self.eventStore else { return }
        let newEvent       = EKEvent(eventStore: eventStore)
        newEvent.calendar  = eventStore.defaultCalendarForNewEvents
        newEvent.startDate = Date(milliseconds: event.start)
        newEvent.endDate   = Date(milliseconds: event.end)
        newEvent.title     = event.name
        newEvent.notes     = "Synced from Whisper: \(event.notes)"
        let alarm = EKAlarm(relativeOffset: TimeInterval(-15*60))
        newEvent.addAlarm(alarm)
        
        do {
            try eventStore.save(newEvent, span: .thisEvent)
        } catch let _ as NSError {
            ToastSuccess(title: "Oh no! We cannot sync your calendar", body: "")
        }
    }
    
    @objc func handleTapNewEvent(_ button: TinderButton ){
        
        guard let eventStore = self.eventStore else { return }
        
        eventStore.requestAccess(to: EKEntityType.event) { (accessGranted, error) in
            if accessGranted{
                DispatchQueue.main.async {
                    self.goOpenCalendar()
                }
            } else {
                DispatchQueue.main.async {
                    return ToastSuccess(title: "We cannot access your calendar", body: "")
                }
            }
        }
    }
    
    
    private func goOpenCalendar(){
        
        guard let eventStore = self.eventStore else { return }
        guard let org = self.org else { return }

        let cohorts = ClubList.shared.fetchClubsFor(school: org).filter{ $0.type == .home }
        if cohorts.count == 0 { return }
        let num = cohorts[0].getPhoneNumber()
        
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(1 * 60 * 60)

        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.calendar  = eventStore.defaultCalendarForNewEvents
        newEvent.startDate = startDate
        newEvent.endDate   = endDate
        newEvent.title     = ""
        let alarm = EKAlarm(relativeOffset: TimeInterval(-15*60))
        newEvent.addAlarm(alarm)

        if let url = UserAuthed.shared.getInstallURL() {
            newEvent.url = url
            newEvent.location = String(describing: url)
            newEvent.notes = "If you do not have Whisper installed on your phone, download from \(url) and use code \(num) to access the space"
        }

        let eventModalVC = EKEventEditViewController()
        eventModalVC.event = newEvent
        eventModalVC.eventStore = eventStore
        eventModalVC.editViewDelegate = self
        self.present(eventModalVC, animated: true, completion: nil)
        
    }
        
}


//MARK:- calendar event delegate

extension CalendarController: EKEventEditViewDelegate {

    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {

        guard let evt = controller.event else {
            return controller.dismiss(animated: true, completion: nil)
        }

        guard let start = evt.startDate?.millisecondsSince1970 else {
            return controller.dismiss(animated: true, completion: nil)
        }
        guard let end = evt.endDate?.millisecondsSince1970 else {
            return controller.dismiss(animated: true, completion: nil)
        }
        guard let tz = evt.timeZone?.identifier else {
            return controller.dismiss(animated: true, completion: nil)
        }
     
        WhisperCalendar.create(
            name    : evt.title ?? "",
            notes   : evt.notes ?? "",
            start   : Int(start),
            end     : Int(end),
            timezone: tz,
            orgID   : self.org?.uuid ?? ""
        ){ id in return }
        controller.dismiss(animated: true, completion: nil)
        
        ToastSuccess(title: "Event created", body: "You will see the update in a few seconds")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
            self?.reload()
        }
    }
        
}

//MARK:- gesture

extension CalendarController : AppHeaderDelegate {

    func onHandleDismiss() {
        AuthDelegate.shared.home?.navigationController?.popViewController(animated: true)
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
            default:
                break
            }
        }
    }

    
}

