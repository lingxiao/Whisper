//
//  Unsafe.swift
//  byte
//
//  Created by Xiao Ling on 5/20/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation


/*
 @Use: All default behaviors that appear hack-y are placed here.
 @Why: often times we add new fields to firestore data that wasn't there before
       if the field need to be incremented, then we have to force a default init value
*/


/*
 @Use: if value is not string, then return ""
 */
func unsafeCastString( _ val : Any? ) -> String {
    guard let str = val as? String else { return "" }
    return str
}

/*
 @Use: if value is not int, then return 1. Major wat
 */
func unsafeCastInt( _ val : Any? ) -> Int{
    guard let n = val as? Int else { return 1 }
    return n
}


/*
 @Use: if value is not int, then return 0
 */
func unsafeCastIntToZero( _ val : Any? ) -> Int{
    guard let n = val as? Int else { return 0 }
    return n
}

func unsafeCastTimeStamp( _ val: Any? ) -> Int {

    guard let time = val as? Int else {
        return ThePast()
    }

    return time
}

/*
 @use: unsafe cast boolean value
 */
func unsafeCastBool(_ val: Any?) -> Bool {
    
    if let b = val as? Bool {
        return b
    } else if let b = val as? Int {
        return b == 0 ? false : true
    } else {
        return false
    }

}

/*
 @Use: force list to list empty list of string
 */
func unsafeCastListOfString( _ val : Any? ) -> [String] {
    guard let xs = val as? [String] else { return [] }
    return xs
}

/*
 @use: extract number from string
 */
func unsafeStringToInt(_ string: String) -> Int?{
    
    let stringArray = string.components(separatedBy: CharacterSet.decimalDigits.inverted)
    let not_em = stringArray.filter{ $0 != "" }
    return not_em.count > 0 ? Int(not_em[0]) : nil
}

/*
 @Use: default to a day before the app is launched
 */
func ThePast() -> Int {
    //let now = Int(TimeInterval(NSDate().timeIntervalSince1970))
    //return now - 60*24*60*60
    return 1584815716
}
