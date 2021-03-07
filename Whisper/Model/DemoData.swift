//
//  DemoData.swift
//  byte
//
//  Created by Xiao Ling on 1/21/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation


//MARK:- dummy users

// https://www.instagram.com/p/BxxOkT8BdNo/
let RandomUserValues = [
    ("Andrew", "m", "m-1"  )
  , ("Richard", "m", "m-2" )
  , ("Alejandr", "m", "m-3")
  , ("Peyton ", "m", "m-4" )
  , ("Brandon", "m", "m-5" )
  , ("Quishon", "m", "m-6" )
  , ("Sanad", "m", "m-7"   )
  , ("Rey ", "m", "m-8"   )

  , ("Mallory", "f", "f-1"  )
  , ("Lynnvi", "f", "f-2"   )
  , ("Stephanie", "f", "f-3")
  , ("Alexandra", "f", "f-4")
  , ("Lindsay", "f", "f-5"  )
  , ("Jennifer", "f", "f-6" )
  , ("Liseth ", "f", "f-7"  )
  , ("Breanna ", "f", "f-8" )
  , ("Hillary", "f", "f-9"  )
  , ("Mallory", "f", "f-10" )
  , ("Uyen ", "f", "f-11"   )
  , ("Amanye", "f", "f-12"  )
]


class RandomUserGenerator {
    
    static let shared = RandomUserGenerator()
    
    private var prev: [String] = []
    private var idx: Int = 0
    
    func getUser() -> (String,String) {
        if idx > RandomUserValues.count - 1 {
            let (str,_,id) = RandomUserValues[0]
            self.idx = 1
            return (str,id)
        } else {
            let (str,_,id) = RandomUserValues[self.idx]
            self.idx += 1
            return (str,id)
        }
    }
    
    
}


func getRandomUser() -> (String,String,String) {
    let k = Int.random(in:0..<RandomUserValues.count-1)
    return RandomUserValues[k]
}


func getTwentyMembers() -> [RoomMember] {

    var res: [RoomMember] = []
    var index: Int = 0

    for (name,_,_) in RandomUserValues {

        let user = User(at: UUID().uuidString)
        user.name = name
        user.numViews = index
        let jt = now() - Int.random(in: 0..<200)
        
        let mem = RoomMember(
            uuid: user.uuid,
            user: user,
            timeStamp: now(),
            joinedTime: jt,
            state: .speaking,
            symbol: "",
            agoraTok: "",
            muted: false,
            currPod: "",
            beat: now()
        )
        res.append(mem)
        index += 1
    }
    
    return res
}

func fromTwentyMember( at user: User? ) -> (String,String) {
    if let user = user {
        let idx = user.numViews
        if idx < RandomUserValues.count {
            let (str,_,im) = RandomUserValues[idx]
            return (str,im)
        } else {
            let (str,_,im) = RandomUserValues[2]
            return (str,im)
        }
    } else {
        let (str,_,im) = RandomUserValues[2]
        return (str,im)
    }
}

func yieldDummyRoomMembers( for num: Int ) -> [RoomMember] {

    var res : [RoomMember] = []
    
    var k = num
    var ith = 0
    
    let db_users = Array(UserList.shared.cached.values)

    while k > 0 {
        
        let index = ith > RandomUserValues.count - 1 ? 0 : ith
        let (xs,_,_) = RandomUserValues[index]
        
        var user = User(at: UUID().uuidString)
        user.name = xs
        user.numViews = index
        
        if !GLOBAL_SHOW_DEMO_PROFILE {
            user = db_users[ Int.random(in: 0..<db_users.count-1) ]
        }
        
        let jt = now() - Int.random(in: 0..<200)
        
        let mem = RoomMember(
            uuid: user.uuid,
            user: user,
            timeStamp: now(),
            joinedTime: jt,
            state: .speaking,
            symbol: "",
            agoraTok: "",
            muted: false,
            currPod: "",
            beat: now()
        )
        res.append(mem)

        k = k - 1
        ith += 1
    }

    return res
}

func getRandomUserValuesFromDummyUser( at user: User? ) -> (String,String) {
    guard let user = user else { return ("","") }
    let res = Array(UserList.shared.cached.values)
    if let k = res.firstIndex(of:user){
        let (rand_name,_,rand_img) = RandomUserValues[k]
        return (rand_name,rand_img)
    } else {
        let idx = min(user.numViews, Int.random(in: 0..<RandomUserValues.count-1) )
        let (rand_name,_,rand_img) = RandomUserValues[idx]
        return (rand_name,rand_img)
    }
}


//MARK:- dummy deck

//
//func yieldDummyDeck( for num: Int ) -> [FlashCardDeck] {
//    
//    var res: [FlashCardDeck] = []
//    
//    var n = num
//    var suffix : Int = 1
//    
//    while n > 0 {
//        let card = FlashCardDeck(at: "class-\(suffix)")
//        switch suffix {
//        case 1:
//            card.name = "3 Dimension: Time/Space"
//        case 2:
//            card.name = "Form and Meaning"
//        case 3:
//            card.name = "Visual Culture"
//        case 4:
//            card.name = "Eye, Mind and Image"
//        case 5:
//            card.name = "Perception"
//        case 6:
//            card.name = "Research Exp Perception"
//        default:
//            break;
//        }
//        res.append(card)
//        n = n - 1
//        suffix += 1
//    }
//    
//    return res
//}
//
//










































