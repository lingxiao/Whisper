//
//  TagModel.swift
//  byte
//
//  Created by Xiao Ling on 2/21/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import Combine
import UIKit


//MARK:- datatype

/*
    Ontology hierachy:
        meta
        TagModel
        OrgModel, ClubModel
 
    rougly corresponds to:
        kind
        type
        term

    in a staticly typed language
*/

enum meta {
    case grad_year
    case sports
    case greeks
    case college
    case ivy
    case sorority
    case fraternity
    case clubs
    case other
}

extension meta : Equatable {
    static func == (lhs: meta, rhs: meta) -> Bool {
        return pp_meta(lhs) == pp_meta(rhs)
    }
}


func pp_meta( _ m: meta ) -> String {
    switch m {
    case .grad_year:
        return "Graduation year"
    case .sports:
        return "Did you play a sport"
    case .greeks:
        return "Greeks"
    case .college:
        return "Alma Mater"
    case .ivy:
        return "Ivy League"
    case .clubs:
        return "Clubs"
    case .sorority:
        return "Were you in a sorority"
    case .fraternity:
        return "Were you in a fraternity"
    case .other:
        return ""
    }
}


func toMeta( _ str: String ) -> meta {
    switch str {
    case "grad_year":
        return .grad_year
    case "sports":
        return .sports
    case "greeks":
        return .greeks
    case "college":
        return .college
    case "ivy":
        return .ivy
    case "clubs":
        return .clubs
    case "sorority":
        return .sorority
    case "fraternity":
        return .fraternity
    default:
        return .other
    }
}


func fromMeta( _ m: meta ) -> String {
    switch m {
    case .grad_year:
        return "grad_year"
    case .sports:
        return "sports"
    case .greeks:
        return "greeks"
    case .college:
        return "college"
    case .ivy:
        return "ivy"
    case .sorority:
        return "sorority"
    case .fraternity:
       return "fraternity"
    case .clubs:
        return "clubs"
    case .other:
        return "other"
    }
}


//MARK:- model

class TagModel : Sink {
    
    var uid: String = ""
    var name: String = ""
    var meta: [meta] = []
    var timeStamp: Int = 0
    
    var creatorID: String = ""
    var clubIDs: [ClubID] = []
    var orgsIDs: [String] = []

    // unique id
    var uuid : UniqueID {
        get { return self.uid }
        set { return }
    }

    init( at id: String! ){
        self.uid = id
    }
    
    func await() {

        // root
        TagModel.rootRef(at: self.uuid)?.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            self.name = unsafeCastString(data["name"])
            self.creatorID = unsafeCastString(data["creatorID"])
            self.timeStamp = unsafeCastInt(data["timeStamp"])
            if let ms = data["meta"] as? [String] {
                self.meta = ms.map{ toMeta($0) }
            }
        }
                
        // clubs and orgs
        TagModel.taggedClubCol(at: self.uuid)?
            .addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else { return }
                for doc in docs {
                    guard let data = doc.data() as? FirestoreData else { continue }
                    guard let id = data["clubID"] as? String else { continue }
                    guard let oid = data["orgID"] as? String else { continue }
                    if id != "" {
                        self.clubIDs.append(id)
                        self.clubIDs = Array(Set(self.clubIDs))
                    }
                    if oid != "" {
                        self.orgsIDs.append(oid)
                        self.orgsIDs = Array(Set(self.orgsIDs))
                    }
                }
            }
    }
        
}

//MARK:- write-

extension TagModel {
    
    // Add meta information to the tag
    func addMeta( for xs: [meta] ){
        self.meta.append(contentsOf:xs)
        let res = Array(Set(self.meta)).map{ fromMeta($0) }
        TagModel.rootRef(at: self.uuid)?.updateData(["meta":res]){ e in return }
    }
    
    // @use: tag the org
    func tag(org:OrgModel?){
        guard let org = org else { return }
        if org.uuid == "" { return }
        let res : FirestoreData = [
            "ID"       : org.uuid,
            "clubID"   : "",
            "orgID"    : org.uuid,
            "userID"   : UserAuthed.shared.uuid,
            "timeStamp": now()
        ]
        TagModel.taggedClubCol(at: self.uuid)?.document(org.uuid).setData( res ){ e in return }
    }
    
    // tag a club
    func tag(club: Club?){

        guard let club = club else { return }
        if club.uuid == "" { return }
        let res : FirestoreData = [
            "ID"       : club.uuid,
            "clubID"   : club.uuid,
            "orgID"    : club.getOrg()?.uuid ?? "",
            "userID"   : UserAuthed.shared.uuid,
            "timeStamp": now()
        ]
        TagModel.taggedClubCol(at: self.uuid)?.document(club.uuid).setData( res ){ e in return }
    }
    
    // untag the club
    func untag(club: Club?){
        guard let club = club else { return }
        if club.uuid == "" { return }
        TagModel.taggedClubCol(at: self.uuid)?
            .document(club.uuid)
            .delete(){ e in return }
    }

}



//MARK:- renderable + read

extension TagModel: Renderable {

    // If tagged this org, then output true
    func taggedThisOrg( at org: OrgModel? ) -> Bool {
        guard let org = org else { return false }
        return self.orgsIDs.contains(org.uuid)
    }
    

    // If tagged this club, then output true
    func taggedThis( club: Club? ) -> Bool {
        guard let club = club else { return false }
        return self.clubIDs.contains(club.uuid)
    }
    
    func get_H1() -> String {
        return name
    }
    
    func get_H2() -> String {
        let prefix = clubIDs.count > 1 ? "\(clubIDs.count) channels tagged" : "One channel tagged"
        return "\(prefix) tagged"
    }
    
    func get_H3() -> Int {
        let n = name.replacingOccurrences(of: "s", with: "", options: .literal, range: nil)
        return Int(n) ?? 0
    }
    
    func fetchThumbURL() -> URL? {
        return nil
    }
    
    func match(query: String?) -> Bool {
        return false
    }
    
    func should_bold_h2() -> Bool {
        return false
    }
        
}

//MARK:- static

extension TagModel : Equatable {
    
    static func == (lhs: TagModel, rhs: TagModel) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    static func create( name: String, meta: [meta], _ then: @escaping(String) -> Void ){
        
        let tags = Array(ClubList.shared.tags.values).filter{ $0.get_H1() == name }

        if tags.count > 0 {

            return then("")

        } else {
            
            // get club id
            let uuid = UUID().uuidString
            let host = UserAuthed.shared.uuid

            // club root data
            let blob : FirestoreData = [
                "ID"             : uuid ,
                "timeStamp"      : now(),
                "timeStampLatest": now(),
                "creatorID"      : host,
                "name"           : name,
                "meta"           : meta.map{ fromMeta($0) }
            ]
            
            TagModel.rootRef(at: uuid)?.setData(blob){ e in
                return then(uuid)
            }

        }

    }

    static func colRef() -> CollectionReference? {
        guard AppDelegate.shared.onFire() else { return nil }
        return AppDelegate.shared.fireRef?.collection("tags")
    }
        
    static func rootRef(at id: String?) -> DocumentReference? {
        guard let id = id else { return nil }
        if id == "" { return nil }
        return TagModel.colRef()?.document(id)
    }
    
    static func taggedClubCol(at id: String?) -> CollectionReference? {
        return rootRef(at: id)?.collection("clubs")
    }
    
}
