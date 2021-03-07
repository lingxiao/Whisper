//
//  UtilityFunctions.swift
//  alpha
//
//  Created by Xiao Ling on 4/16/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//


import Foundation
import Contacts


//MARK:- money utils

/*
 @use: convert ie: $4.99 = 4990
 */
func toCurrency( from val : Double? ) -> Int {

    guard let v = val else {
        return 0
    }
    
    return Int(v * 100)
}

func fromCurrency( from val : Int? ) -> Double {

    guard let v = val else {
        return Double(0)
    }
    
    return Double(v/100)
}


//MARK:- user utilites


func sortIds( ids : [String] ) -> [String] {
    let unique_userIds = Array(Set(ids))
    let sortedUserIds = unique_userIds.sorted { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }
    return sortedUserIds
}

func generateSearchQueriesForUser( name: String, email: String) -> [String] {
/*
     @Use: generate queries from name and email for graphql search
*/
    
    var res : [String] = []

    let rootEmail = email.components(separatedBy: "@")[0]
    res.append(rootEmail)

    res.append( name )
    let frags = name.components(separatedBy:[",", " ", "!",".","?", "_", "-"])
    res.append(contentsOf: frags)

    
    /// filter out empty string and remove repats
    res = res.filter { $0 != "" }
    res = Array(Set(res))
    
    /// lowercase everything
    res = res.map{ $0.lowercased() }


    return res
}



// MARK:- string utils

func checkValidEmail(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
}

func generatePassword( email: String ) -> String {
// @Use: for the purpose of testing, password is the same as email
    let prefix : String = "64439638952027"
    let suffix : String = "1904383418681"
    let root   : String = String(email.reversed())
    return "\(prefix)_\(root)_\(suffix)"
}



func validateIFSC(code : String) -> Bool {
  let regex = try! NSRegularExpression(pattern: "^[A-Za-z]{4}0.{6}$")
  return regex.numberOfMatches(in: code, range: NSRange(code.startIndex..., in: code)) == 1
}


//MARK:-  Phonenumber create

public func randomPhoneNumber() -> String {
    return randomNums(digits: 10)
}

private func randomNums(digits:Int) -> String {
    var number = String()
    for _ in 1...digits {
       number += "\(Int.random(in: 1...9))"
    }
    return number
}



//MARK:-  Phonenumber uils

func formatPhoneNumber( _ sourcePhoneNumber: String) -> String? {
    // Remove any character that is not a number
    let numbersOnly = sourcePhoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    let length = numbersOnly.count
    let hasLeadingOne = numbersOnly.hasPrefix("1")

    // Check for supported phone number length
    guard length == 7 || (length == 10 && !hasLeadingOne) || (length == 11 && hasLeadingOne) else {
        return nil
    }

    let hasAreaCode = (length >= 10)
    var sourceIndex = 0

    // Leading 1
    var leadingOne = ""
    if hasLeadingOne {
        leadingOne = "1 "
        sourceIndex += 1
    }

    // Area code
    var areaCode = ""
    if hasAreaCode {
        let areaCodeLength = 3
        guard let areaCodeSubstring = numbersOnly.substring(start: sourceIndex, offsetBy: areaCodeLength) else {
            return nil
        }
        areaCode = String(format: "(%@) ", areaCodeSubstring)
        sourceIndex += areaCodeLength
    }

    // Prefix, 3 characters
    let prefixLength = 3
    guard let prefix = numbersOnly.substring(start: sourceIndex, offsetBy: prefixLength) else {
        return nil
    }
    sourceIndex += prefixLength

    // Suffix, 4 characters
    let suffixLength = 4
    guard let suffix = numbersOnly.substring(start: sourceIndex, offsetBy: suffixLength) else {
        return nil
    }

    return leadingOne + areaCode + prefix + "-" + suffix
}

