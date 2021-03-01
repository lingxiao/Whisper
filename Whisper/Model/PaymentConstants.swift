//
//  PaymentConstants.swift
//  byte
//
//  Created by Xiao Ling on 11/10/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation


//MARK:- subscription



/*
 @use: coins users purchase to bid.
    * One coin convert to 10 cents at payout time
 */
struct SUBSCRIBE {
    static let A = subA
    static let B = subB
    static let C = subC
    static let D = subD
}

/*
 @Conversion:
*/
private let subA : FirestoreData = [
      "price": Double(4.59)
    , "text": "Friend"
    , "id": "com.playhouse.basicSub"
    , "name": "monthlyBasic"
]

/*
 @Conversion:
*/
private let subB : FirestoreData = [
      "price": Double(9.99)
    , "text": "Patron"
    , "id": "com.playhouse.familySub"
    , "name": "monthlyFamily"
]

/*
 @Conversion:
*/
private let subC : FirestoreData = [
      "price": Double(29.99)
    , "text": "Premium"
    , "id": "com.playhouse.premiumSub"
    , "name": "monthlyPremium"
]


/*
 @Conversion:
*/
private let subD : FirestoreData = [
      "price": Double(99.99)
    , "text": "VIP"
    , "id": "com.playhouse.vipSub"
    , "name": "monthlyVIP"
]



//MARK:- tips

// when bidding, how many coins to raise by
let RAISE_AMT : Int = 25
let COIN_PAYABLE_THRESHOLD = 100
let COIN_PRICE_IN_CENTS = 10

/*
 @use: coins users purchase to bid.
    * One coin convert to 10 cents at payout time
 */
struct COINS {
    static let A = coinA
    static let B = coinB
    static let C = coinC
    static let D = coinD
}

/*
 @Conversion:  $4.99 USD  =(apple tax)=> $4.49 USD =(rake)=> $3.14 USD
*/
private let coinA : FirestoreData = [
      "price": Double(4.99)
    , "coins": 30
    , "id": "com.playhouse.smallBagOfCoins"
    , "name": "smallBagOfCoins"
]

/*
 @Conversion:  $9.99 USD  =(apple tax)=> $6.99 USD =(rake)=> $ 6.99 USD
*/
private let coinB : FirestoreData = [
      "price": Double(9.99)
    , "coins": 60
    , "id": "com.playhouse.mediumBagOfCoins"
    , "name": "mediumBagOfCoins"
]

/*
 @Conversion:  $29.99 USD  =(apple tax)=> $20.99 USD =(rake)=> $ 18.89 USD
*/
private let coinC : FirestoreData = [
      "price": Double(29.99)
    , "coins": 180
    , "id": "com.playhouse.largeBagOfCoins"
    , "name": "largeBagOfCoins"
]

/*
 @Conversion:  $99.99 USD  =(apple tax)=> $69.99 USD =(rake)=> $ 62.99 USD
*/
private let coinD : FirestoreData = [
      "price": Double(99.99)
    , "coins": 620
    , "id": "com.playhouse.hugeBagOfCoins"
    , "name": "hugeBagOfCoins"
]

