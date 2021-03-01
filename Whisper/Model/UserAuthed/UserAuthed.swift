//
//  UserAuthed.swift
//  byte
//
//  Created by Xiao Ling on 5/18/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import Combine
import FirebaseAuth
import AVFoundation

/*

 @Class: User singelton for my user data
 @States:
 
 @Methods [READ]:
 
 @Methods [WRITE]:

*/


class UserAuthed { 
    
    static var shared : UserAuthed = UserAuthed()
    
    // delegate
    var delegate : AuthedUserDelegate?
    
    // id and names
    var uid      : UserID = ""
    var name     : String?
    var bio      : String = ""
    var email    : String = ""
    var numEdits : Int = 0
    var timeStampLatest: String?
    var queries  : [String] = []

    // sponsor logic
    var new_account   : Bool = false
    var invite_code   : String = ""
    var sponsor_id    : UserID?
    var sponsor       : User?
    var sponsor_club  : String = ""
    
    // if is privilidged user,
    // then give access to certain buttons
    var isPrivUser: Bool = false
    
    // onboard app gesture
    var didSyncContacts: Bool = false
    var did_drag_audio_room: Bool = false
    var did_drag_deck:Bool = false
    var did_switch_rooms: Bool = false
    var did_drag_news_feed: Bool = false
    var did_consent_to_emphemeral_club : Bool = false
    var did_tag_deck_1st_time: Bool = true

    // profile image
    var thumbURL : URL?
    var mediumURL: URL?
    var fullURL  : URL?
    
    // admin url
    var adminURL: URL?
    var installURL: URL?

    // notification token
    var notification_token: String = ""
    var did_link_twitter: Bool = false

    // alerts
    var alerts: [String:AlertBlob] = [:]
    
    // payment
    var stripe_user_id: String = ""
    var purchased_in_coins: Int = 0
    var receivable_in_coins: Int = 0
    
    // time
    var timeSlotStarts : [Int] = []
    var timeSlots: [Int:(Int,String)] = [:]
    
    // current org
    var current_org_id: String = ""
    
    init(){}
    
    // unique id
    var uuid : UniqueID {
        get { return unsafeCastString(self.uid) }
        set { return }
    }

    func syncToRemote( with id: String?, _ then: @escaping() -> Void ){
        guard let id = id else { return }
        if id == "" { return }
        self.uid = id
        awaitRemote(){ (succ,msg) in then() }
        awaitAdminResource()
        awaitAlerts()
    }

    // trivial batch implementation
    func batch() -> [String] {
        return self.queries
    }
}


    
//MARK:- static functions ref


extension UserAuthed {
    
    static func rootRef( for uid : UserID? ) -> DocumentReference? {

        guard let uid = uid else { return nil }
        if uid == "" { return nil }
        
        let ref = AppDelegate.shared.fireRef?
            .collection("users")
            .document( uid )

        return ref
    }
    
    
    static func queryRef( for uid: UserID? ) -> DocumentReference? {

        guard let uid = uid else { return nil }
        if uid == "" { return nil }
        
        let ref = AppDelegate.shared.fireRef?
            .collection("user_queries")
            .document( uid )
        return ref
    }
    
    static func paymentRef( for uid: UserID? ) -> DocumentReference? {
        
        guard let uid = uid else { return nil }
        if uid == "" { return nil }
        
        let ref = AppDelegate.shared
            .fireRef?.collection("balance").document(uid)
        return ref
    }
    
    static func stripeRef()  -> DocumentReference? {
        let uid = UserAuthed.shared.uuid
        if uid == "" { return nil }
        let ref = AppDelegate.shared
            .fireRef?.collection("users_stripe").document(uid)
        return ref
    }
    
    static func viewRef( for uid: UserID? ) -> DocumentReference? {
        guard let ref = rootRef(for: uid) else { return nil }
        return ref.collection("stats").document("view")
    }
    
    static func sponsorRef( for uid: UserID? ) -> DocumentReference? {
        guard let ref = rootRef(for: uid) else { return nil }
        return ref.collection("stats").document("sponsorship")
    }

    static func statisticsRef( for uid: UserID? ) -> DocumentReference? {
        guard let ref = rootRef(for: uid) else { return nil }
        return ref.collection("stats").document("aggregate")
    }
    
    static func onboardWalkThruRef( for uid: UserID? ) -> DocumentReference? {
        guard let ref = rootRef(for: uid) else { return nil }
        return ref.collection("stats").document("onboarding")
    }

    static func clubCollectionRef( for uid: UserID? ) -> CollectionReference? {
        return rootRef(for: uid)?.collection("clubs")
    }
        
    static func clubRef( for uid: UserID?, at cid: String? ) -> DocumentReference? {
        guard let cid = cid else { return nil }
        if cid == "" { return nil }
        return UserAuthed.clubCollectionRef(for: uid)?.document(cid)
    }
    
    static func alertCol() -> CollectionReference? {
        let ref = AppDelegate.shared.fireRef?.collection("user_alerts")
        return ref
    }
    
    static func contactsRef( at id: String ) -> DocumentReference? {
        if id == "" { return nil }
        return AppDelegate.shared.fireRef?.collection("address_book").document(id)
    }
    
    static func contactsHostUser( at id: String, from uid: String ) -> DocumentReference? {
        if id == "" || uid == "" { return nil }
        return AppDelegate.shared.fireRef?
            .collection("address_book")
            .document(id)
            .collection("users")
            .document(uid)
    }

}


//MARK:- static functions write

extension UserAuthed {
    
    /**
     @Use: Class Function: create my user blob
    */
    static func createUser( with email: String, phone:String?, _ complete: @escaping (Bool, String) -> Void ){

        guard let userID = Auth.auth().currentUser?.uid else {
            return complete(false, "User not authenticated")
        }
        
        guard AppDelegate.shared.onFire() else {
            return complete(false, "improperly configured firebase ref")
        }

        AppDelegate.shared.fireRef?
            .collection("users")
            .document( userID )
            .getDocument{( documentSnapshot, error) in

                if ( error != nil || documentSnapshot == nil){
                    complete(false, "Failed to get reach firebase backend")
                    return
                }
                
                guard let document = documentSnapshot else {
                    complete(false, "Failed to get reach firebase backend")
                    return
                }
                
                if document.data() != nil {
                    complete(true, "user already exist!")
                    return
                }

                // create an invite-code I give out to others
                let emailRoot = email.components(separatedBy: "@")[0]

                let blob_view : FirestoreData = [

                      "name"   : emailRoot
                    , "userID" : userID
                    , "email"  : email
                    , "phone"  : unsafeCastString(phone)
                    , "bio"    : ""
                    , "numEdits": 0
                    
                    // profile images
                    , "profileImageLarge"  : ""
                    , "profileImageMedium" : ""
                    , "profileImageSmall"  : ""
                    
                    // social media plug
                    , "tikTok"   : ""
                    , "instagram": ""
                    , "twitter"  : ""
                    , "youtube"  : ""
                    , "spotify"  : ""
                    , "linkedin" : ""
                    , "website"  : ""

                    // push notification
                    , "pushNotificationToken": ""
                ]

                let blob_sponsor: FirestoreData = [
                      "sponsor"     : ""
                    , "invite_code" : "" // code I received to sign up for app
                    , "new_account" : true
                    , "userID"      : userID
                    , "sponsor_club": ""
                ]
                
                     
                // base blob
                let blob : FirestoreData = [
                      "userID"          : userID
                    , "timeStampCreated": now()
                    , "timeStampLatest" : now()
                    , "serverSet": false
                    , "isPrivUser": false
                ]
                
                let blob_onboard: FirestoreData = [
                    "timeStamp": now(),
                    "did_tag_deck": false,
                    "did_drag_audio_room": false,
                    "did_drag_deck": false,
                    "did_switch_rooms": false,
                    "did_drag_news_feed": false,
                    "did_consent_to_emphemeral_club": false,
                    "didSyncContacts": false
                ]
                
                // build queries with [ email, emailRoot, phoneNumber ]
                var queries = generateSearchQueriesForUser( name: "", email: email )
                queries.append( email )
                let q_blob : FirestoreData = [
                    "query": queries,
                    "userID": userID,
                    "timeStamp": now()
                ]
                
                let root = AppDelegate
                    .shared
                    .fireRef?
                    .collection("users")
                    .document(userID)
                
                root?.setData( blob ){ err in

                    if let err = err {

                        complete( false, "Failed with \(err)")

                    } else {

                        // call completion
                        complete( true, "success")
                        
                        // record view
                        root?.collection("stats")
                            .document("view")
                            .setData( blob_view ){ e in return }
                        
                        // record social
                        root?.collection("stats")
                            .document("sponsorship")
                            .setData( blob_sponsor ){ e in return }
                        
                        UserAuthed.onboardWalkThruRef(for: userID)?
                            .setData( blob_onboard ){ e in return }

                        // save query
                        AppDelegate.shared.fireRef?
                            .collection("user_queries")
                            .document( userID )
                            .setData( q_blob ){ e in return }

                        // create wallet and give the user 20 coins
                        var wallet = blankWallet(for: userID)
                        wallet["purchased_in_coins"] = RAISE_AMT
                        
                        AppDelegate.shared
                            .fireRef?
                            .collection("balance")
                            .document(userID)
                            .setData( wallet ){ err in return }

                    }
                }
        }
    }
    
    
    // @use: create empty user
    static func makeUserRecordStub( _ uid: UserID ) -> FirestoreData {
        return makeMemberStub(uid)
    }

    
}



//MARK: - uploadimage

extension UserAuthed {
    
    /*
     @Use: upload image to firebase storage
    */
    static func uploadImage( to path: String,  with data: Data?, _ complete: @escaping Completion ){
        
        guard let data = data else { return complete(false,"") }
        guard let storageRef = AppDelegate.shared.storeRef?.reference().child(path) else {
            return complete( false, "" )
        }

        storageRef.putData( data, metadata:nil){ (metadata,error) in

            guard let _ = metadata else {
                return complete(false,"")
            }

            storageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    return complete(false, "")
                }
                let url = String(describing: downloadURL)
                return complete( true, url )
            }
        }
    }
    
    // delete data
    static func deleteMedia( at path: String ){

        if path == "" { return }

        guard let storageRef = AppDelegate.shared.storeRef?.reference().child(path) else {
            return
        }
        
        storageRef.delete(){ e in return }

    }
    
    static func uploadVideo( to uuid: String, with url: URL?, _ then : @escaping (String,String) -> Void){
        

        guard let url = url else { return then("","") }
        guard AppDelegate.shared.canStore() else { return then("","") }

        let name = "\(uuid).mp4"
        let path = NSTemporaryDirectory() + name

        let dispatchgroup = DispatchGroup()

        dispatchgroup.enter()

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputurl = documentsURL.appendingPathComponent(name)
        var ur = outputurl

        convertVideo(toMPEG4FormatForVideo: url as URL, outputURL: outputurl) { (session) in
            ur = session.outputURL!
            dispatchgroup.leave()
        }
        dispatchgroup.wait()

        let data = NSData(contentsOf: ur as URL)

        do {

            try data?.write(to: URL(fileURLWithPath: path), options: .atomic)

        } catch {

            return then("","")
        }

        guard let uploadData = data as? Data else {
            return then("","")
        }

        let storageRef = Storage.storage().reference().child("Videos").child(name)

        storageRef.putData( uploadData, metadata:nil){ (metadata,error) in

            guard let _ = metadata else {
                return then("","")
            }

            storageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    return then("","")
                }
                let url = String(describing: downloadURL)
                return then( url, "Videos/\(name)" )
            }
        }

    }
    
}


