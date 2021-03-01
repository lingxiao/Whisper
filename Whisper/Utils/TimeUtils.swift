//
//  TimeUtils.swift
//  byte
//
//  Created by Xiao Ling on 5/18/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation



//MARK:- compute elapsed time in minutes


func stringToDate( _ time : String ) -> Date {
    
    let _past : TimeInterval = (time as NSString).doubleValue
    let past = NSDate(timeIntervalSince1970:_past)

    return past as Date
}

func now() -> Int {
    return Int(TimeInterval(NSDate().timeIntervalSince1970))
}


func dayOfWeekAndDay() -> (String,String) {

    let today = Date()
    let mo = DateFormatter()
    mo.timeZone = .current
    mo.dateFormat = "EEEE"

    let day = DateFormatter()
    day.timeZone = .current
    day.dateFormat = "d"

    let smo = mo.string(from: today)
    let sday = day.string(from: today)

    return (smo,sday)
}

//MARK:- second to ( hr, min , sec )

func secondsToHoursMinutesSeconds (_ seconds : Int) -> (Int, Int, Int) {
  return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}

func computeAgo(from t: Int) -> String {

    let dt = now() - t
    if dt <= 0 { return "1s ago" }
    let ( dh, dm, ds ) = secondsToHoursMinutesSeconds(dt)
    let dd = dh > 24 ? dh/24 : 0

    if dd > 0 {
        return "\(dd)d ago"
    } else if dh > 0 {
        return "\(dh)h ago"
    } else if dm > 0 {
        return "\(dm)m ago"
    } else if ds > 0 {
        return "\(ds)s ago"
    } else {
        return "1s ago"
    }
}


// MARK: -pretty time time

func prettifyTime( at epochTime: String?) -> String {
    
    guard let epochTime = epochTime else { 
        return ""
    }

    // special case where timstamp is not defined
    if ( epochTime == "" ){
        return ""
    }

    guard let _interval = TimeInterval(epochTime) else { //as? TimeInterval else {
        return ""
    }
    
    let currentDate = Date()
    let epochDate = Date(timeIntervalSince1970: _interval )

    let calendar = Calendar.current

    let currentDay = calendar.component(.day, from: currentDate)
    let currentHour = calendar.component(.hour, from: currentDate)
    let currentMinutes = calendar.component(.minute, from: currentDate)
    let currentSeconds = calendar.component(.second, from: currentDate)

    let epochDay = calendar.component(.day, from: epochDate)
    let epochMonth = calendar.component(.month, from: epochDate)
    let epochYear = calendar.component(.year, from: epochDate)
    let epochHour = calendar.component(.hour, from: epochDate)
    let epochMinutes = calendar.component(.minute, from: epochDate)
    let epochSeconds = calendar.component(.second, from: epochDate)

    if (currentDay - epochDay < 30) {
        if (currentDay == epochDay) {
            if (currentHour - epochHour == 0) {
                if (currentMinutes - epochMinutes == 0) {
                    if (currentSeconds - epochSeconds <= 1) {
                        return currentSeconds - epochSeconds < 0 ? "Just now" : String(currentSeconds - epochSeconds) + " second ago"
                    } else {
                        return String(currentSeconds - epochSeconds) + " seconds ago"
                    }

                } else if (currentMinutes - epochMinutes <= 1) {
                    return currentMinutes - epochMinutes < 0 ? "Just now" : String(currentMinutes - epochMinutes) + " minute ago"
                } else {
                    return String(currentMinutes - epochMinutes) + " minutes ago"
                }
            } else if (currentHour - epochHour <= 1) {
                return currentHour - epochHour < 0 ? "1 hour ago" : String(currentHour - epochHour) + " hour ago"
            } else {
                return String(currentHour - epochHour) + " hours ago"
            }
        } else if (currentDay - epochDay <= 1) {
            return currentDay - epochDay < 0 ? "1 day ago" : String(currentDay - epochDay) + " day ago"
        } else {
            return String(currentDay - epochDay) + " days ago"
        }
    } else {
        return String(epochDay) + " " + getMonthNameFromInt(month: epochMonth) + " " + String(epochYear)
    }
}


func getMonthNameFromInt(month: Int) -> String {
    switch month {
    case 1:
        return "Jan"
    case 2:
        return "Feb"
    case 3:
        return "Mar"
    case 4:
        return "Apr"
    case 5:
        return "May"
    case 6:
        return "Jun"
    case 7:
        return "Jul"
    case 8:
        return "Aug"
    case 9:
        return "Sept"
    case 10:
        return "Oct"
    case 11:
        return "Nov"
    case 12:
        return "Dec"
    default:
        return ""
    }
}

