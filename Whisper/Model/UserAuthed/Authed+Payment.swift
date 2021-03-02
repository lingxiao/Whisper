//
//  Authed+Payment.swift
//  byte
//
//  Created by Xiao Ling on 8/17/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import Firebase
import Combine
import FirebaseAuth
import SwiftyStoreKit


//MARK:- utils

// @use: make blank wallet
func blankWallet( for uid : String ) -> FirestoreData{

    let res : FirestoreData = [
           "userId": uid

         , "receivable_in_coins"  : 0  // amount Playhouse need to payout to this user in coins
         , "purchased_in_cents"   : 0  // amount the user have bought in cents
         , "purchased_in_coins"   : 0  // amoutn of coins user have purchased

         , "total_sales_in_coins" : 0   // amt sold in coins
         , "total_sales_in_cents" : 0   // total amt sold in USD
         , "total_profit_in_cents": 0   // how much user took home in USD
         , "timeStamp": now()
    ]

    return res
    
}


//MARK:- Get data

extension UserAuthed {
    
    /*
        @use: await stripe deposit account
    */
    func awaitStripeDeposit(){
        
        let stripeRef = UserAuthed.stripeRef()
        let balanceRef = UserAuthed.paymentRef(for: self.uuid)

        stripeRef?.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else { return }
            guard let data = document.data() as FirestoreData? else { return }
            self.stripe_user_id = unsafeCastString(data["stripe_user_id"])
        }


        balanceRef?.addSnapshotListener { documentSnapshot, error in

                // parse
                guard let document = documentSnapshot else { return }
                guard let data = document.data() as FirestoreData? else { return }

                self.purchased_in_coins = unsafeCastIntToZero(data["purchased_in_coins"])
                
                let prev_receivable_in_coins = self.receivable_in_coins
                self.receivable_in_coins = unsafeCastIntToZero(data["receivable_in_coins"])

                if self.receivable_in_coins > COIN_PRICE_IN_CENTS * COIN_PAYABLE_THRESHOLD {
                    
                    // wait so that events do not conflict
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3 ) { [unowned self] in
                        if self.stripe_user_id == "" {
                            self.delegate?.shouldEnterBankAccount()
                        }
                    }
                    
                }
                
                if self.receivable_in_coins > prev_receivable_in_coins {
                    self.delegate?.didEarnCoins( amt: self.receivable_in_coins )
                }
        }
    }
}

//MARK:- API

extension UserAuthed {
    
    /*
     @use: redirect to this page after authenticating with stripe
     */
    func stripeRedirectURL() -> URL? {
        // https://dashboard.stripe.com/settings/applications
        let client_ID = "ca_J2Rw8ve1TpIobX0Zh63Tx27Z9Uv4KQpa"
        let redirect  = "https://play-house-social.web.app/deposit_info"
        let raw  = "https://connect.stripe.com/express/oauth/authorize?redirect_uri=\(redirect)&client_id=\(client_ID)&state=\(self.uuid)"
        return URL(string: raw)
    }
    
}





//MARK:- DEPRICATED-

extension UserAuthed {

    /*
     @use: check if there is sufficient funds
    */
    func assertSufficientFunds( for numCoins: Int? ) -> Bool {
        return false
//        if let amt = numCoins {
//            return amt <= self.purchased_in_coins
//        } else {
//            return true
//        }
    }

    // @use: clear cache of hosts i paid this session
    func resetCheckpoint(){
        //self.session_payments = []
    }
    

    /*
     @use: I pay uid amt
    */
    func payHost( to host: User?, _ then: @escaping Completion ){
        
//        guard let host = host else {
//            then(false, "No host specified")
//            return
//        }
//
//        // get highest bid
//        let my_bids = Array(host.audience.values)
//            .filter{ $0.uuid == UserAuthed.shared.uuid }
//
//        if my_bids.count == 0 {
//            then(false, "I did not bid")
//            return
//        }
//
//        if session_payments.contains( host.uuid ){
//            then(false, "I already paid host this session")
//            return
//        }
//
//        var max_bid : Int = 0
//
//        for blob in my_bids {
//            if blob.bid_in_coins > max_bid {
//                max_bid = blob.bid_in_coins
//            }
//        }
//
//        // check i have enough funds. else don't pay
//        if self.assertSufficientFunds(for: max_bid) == false {
//            then( false, "Insufficient funds" )
//            return
//        } else {
//            goPayHost(to : host, with: max_bid ){ (succ, msg) in
//                then(succ,msg)
//            }
//            return
//        }

    }
    
    private func goPayHost( to host: User, with max_bid: Int, then : @escaping Completion ){
        /*
        // increment account receivable for host
        func incr_host_wallet( blob : FirestoreData? ) -> FirestoreData? {
            
            if var update = blob {
            
                update["timeStamp"] = now()
                update["receivable_in_coins"]  = unsafeCastIntToZero(update["receivable_in_coins"])  + max_bid
                update["total_sales_in_coins"] = unsafeCastIntToZero(update["total_sales_in_coins"]) + max_bid
                return update
                
            } else {
                
                var wallet = blankWallet(for: host.uuid)
                wallet["receivable_in_coins"]  = max_bid
                wallet["total_sales_in_coins"] = max_bid
                
                return wallet
            }
        }
        
        
        goMutate( root: "balance", userId: host.uuid, step: incr_host_wallet ){(succ,msg) in
            self.session_payments.append( host.uuid )
            return then(succ,msg)
        }
        
        // decrement my coins
        func decr_my_wallet( blob : FirestoreData? ) -> FirestoreData? {
            
            if var update = blob {

                update["timeStamp"] = now()
                let delta = unsafeCastIntToZero(update["purchased_in_coins"]) - max_bid
                update["purchased_in_coins"]  = delta > 0 ? delta : 0
                return update

            } else {
                
                return blankWallet(for: self.uuid)
            }
        }

        goMutate( root: "balance", userId: self.uuid, step: decr_my_wallet ){(succ,msg) in
            return
        }
        
        // record transation
        let trans_id = UUID().uuidString
        
        let record : FirestoreData = [
            "uuid": trans_id,
            "donor": self.uuid,
            "benefactor": host.uuid,
            "num_coins": max_bid,
            "timeStamp": now(),
            "userIds": [self.uuid, host.uuid]
            
        ]
                
        AppDelegate
            .shared
            .fireRef?
            .collection("log_bid_fill")
            .document(trans_id).setData( record ){ err in return }
        
        // log event
        Analytics.logEvent(AnalyticsEventSpendVirtualCurrency, parameters: [
            AnalyticsParameterItemName: "pay_host",
            AnalyticsParameterValue: max_bid,
            AnalyticsParameterVirtualCurrencyName: host.uuid
        ])
         */
    }
    
    
    func fetchCoin( for coin: FirestoreData?, _ then: @escaping (Bool,String) -> Void){
        
        /*guard let coin = coin else { return then(false,"No coins specified") }
        guard let id = coin["id"] as? String else { return then(false, "No purchase id specified") }
        
        Analytics.logEvent("purchae_init", parameters: [
            "name": id as NSObject
        ])
        
        // retreive product
        SwiftyStoreKit.retrieveProductsInfo([id]) { result in
            if let _ = result.retrievedProducts.first {
                return then(true, "Merch exists")
            } else if let invalidProductId = result.invalidProductIDs.first {
                return then(false, "Invalid product identifier: \(invalidProductId)")
            } else {
                return then(false,"Error: \(result.error)")
            }
        }*/
    }
    
    /*
     @Use: buy trial merchandize
    */
    func buyCoin( for coin: FirestoreData?, _ then: @escaping (Bool,String) -> Void){

        guard let coin = coin else { return then(false,"No coins specified") }
        guard let id = coin["id"] as? String else { return then(false, "No purchase id specified") }

        SwiftyStoreKit.purchaseProduct(id, quantity: 1, atomically: true) { result in
                        
            // get receipt data
            let receiptData = SwiftyStoreKit.localReceiptData
            let receiptString = receiptData?.base64EncodedString(options: [])
                        
            switch result {

            case .success(let purchase):
                    
                // reload wallet with new coins
                self.rechargeWallet ( with: coin )

                // call back
                then(true, "Purchase Success: \(purchase.productId)")

                /*
                 @Use: validate and share receipt with apple.
                 @DOC: https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox
                 @DOC: https://www.appypie.com/faqs/how-can-i-get-shared-secret-key-for-in-app-purchase
                 @DOC: https://help.apple.com/app-store-connect/#/dev8b997bee1
                 @DOC: https://appstoreconnect.apple.com/access/shared-secret
                */
                let SECRET = "31c231a914ec4c179817abe0a4b7742f" // 320e65bd98384031a8bde803249c235a
                
                let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: SECRET)
                
                SwiftyStoreKit.verifyReceipt(using: appleValidator, forceRefresh: false) { result in
                    
                    switch result {
                    case .success(let receipt):
                        self.logCoinPurchase( for: coin, with: receiptString, log: receipt )
                    case .error(let error):
                        let blob : FirestoreData = [
                              "error": error.localizedDescription
                            , "timeStamp": now()
                        ]
                        self.logCoinPurchase( for: coin, with: receiptString, log: blob )
                    }
                }
                

            case .error(let error):
                switch error.code {
                case .unknown:
                    then(false,"Unknown error. Please contact Apple")
                case .clientInvalid:
                    then(false,"Not allowed to make the payment")
                case .paymentCancelled:
                    then(false, "payment canceled")
                case .paymentInvalid:
                    then(false, "The purchase identifier was invalid")
                case .paymentNotAllowed:
                    then(false, "The device is not allowed to make the payment")
                case .storeProductNotAvailable:
                    then(false, "The product is not available in the current storefront")
                case .cloudServicePermissionDenied:
                    then(false, "Access to cloud service information is not allowed")
                case .cloudServiceNetworkConnectionFailed:
                    then(false, "Could not connect to the network")
                case .cloudServiceRevoked:
                    then(false, "User has revoked permission to use this cloud service")
                default:
                    then(false,(error as NSError).localizedDescription)
                }
            }
        }
    }

    //MARK:- Utils


    /*
     @use: Record use's balance
    */
    private func rechargeWallet( with coin: FirestoreData? ){
        
        guard let coin = coin else { return }
        guard let price = coin["price"] as? Double else { return }
        guard let num_coins = coin["coins"] as? Int else { return }
        
        let val = toCurrency(from: price)

        func step( blob : FirestoreData? ) -> FirestoreData? {

            if var update = blob {

                update["purchased_in_cents"] = unsafeCastIntToZero(update["purchased_in_cents"]) + val
                update["purchased_in_coins"] = unsafeCastIntToZero(update["purchased_in_coins"]) + num_coins
                update["timeStamp"] = now()
                return update

            } else {

                var res = blankWallet(for: self.uuid)
                res["purchased_in_cents"] = val
                res["purchased_in_coins"] = num_coins

                return res
            }
        }
        
        self.goMutate( root: "balance", userId: self.uuid, step: step ){(succ,msg) in return }
    }

        
    /*
     @use: log merchandize purchased in global feed
     */
    private func logCoinPurchase( for coin : FirestoreData?, with receipt: String?, log: FirestoreData? ){

        let purchase_id = UUID().uuidString
        
        guard var coin = coin else { return }
        coin["uuid"] = purchase_id
        coin["userId"] = self.uuid
        coin["timeStamp"] = now()

        if let str = receipt {
            coin["receiptData"] = str
        } else {
            coin["receiptData"] = ""
        }

        AppDelegate.shared.fireRef?
            .collection("log_coin_purchase")
            .document( purchase_id )
            .setData( coin ){ err in return }
        
        if let log = log {
            AppDelegate.shared.fireRef?
                .collection("log_coin_purchase")
                .document( purchase_id )
                .collection("receipt")
                .document( purchase_id )
                .setData( log ){ err in return }
        }

    }
    
}


extension UserAuthed {

    /*
     @Use: common fuction to mutate my user's state. all functions
           that mutate my state must call this function
     */
    private func goMutate(
          root: String
        , userId: String
        , step: @escaping  (FirestoreData?) -> FirestoreData?
        , _ complete: @escaping Completion){
        
        guard AppDelegate.shared.onFire() else {
            return complete(false, "improperly configured firebase ref")
        }
        
        let userID: String = userId

        if userID == "" {
            return complete( false, "UserID cannot be empty string" )
        }

        let ref = AppDelegate
            .shared
            .fireRef?
            .collection(root)
            .document( userID )
        
        ref?.getDocument{( documentSnapshot, error) in
                
            if ( error != nil || documentSnapshot == nil){
                return complete(false, "Failed to get reach firebase backend")
            }
            
            guard let document = documentSnapshot else {
                return complete( false, "failed to snap document" )
            }

            let update = step( document.data() as? FirestoreData )
            
            guard (update != nil) else {
                return complete(false, "invalid update")
            }

            ref?.setData( update! ){ err in
                if let err = err {
                    complete(false, "Failed with \(err)")
                } else {
                    complete(true,"done")
                }
            }
        }
    }

    
}
