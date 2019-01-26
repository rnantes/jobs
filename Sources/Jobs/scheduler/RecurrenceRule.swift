//
//  ReccurrenceRules.swift
//  App
//
//  Created by Reid Nantes on 2019-01-26.
//

import Foundation

struct RecurrenceRule {
    let year: Int?
    let month: Int?
    let dayOfMonth: Int?
    let dayOfWeek: Int?
    let hour: Int?
    let minute: Int?
    let second: Int?

    // year (>1)
    // month (1-12) ex: 1 january, 12 December
    // dayOfMonth (1-31) ex: 1 1st of month, 31 31st of month
    // dayOfWeek (0-6) ex: 0 sunday, 6 saturday
    // hour: Int (0-23)
    // minute: Int (0-59)
    // second: Int (0-59)
    init?(year: Int? = nil,
          month: Int? = nil,
          dayOfMonth: Int? = nil,
          dayOfWeek: Int? = nil,
          hour: Int? = nil,
          minute: Int? = nil,
          second: Int? = nil) {
        // validate year
        if let year = year {
            if year > 0 {
                self.year = year
            } else {
                return nil
            }
        } else {
            self.year = nil
        }

        // validate month
        if let month = month {
            if month >= 1 && month <= 12 {
                self.month = month
            } else {
                return nil
            }
        } else {
            self.month = nil
        }

        // validate dayOfMonth
        if let dayOfMonth = dayOfMonth {
            if dayOfMonth >= 1 && dayOfMonth <= 31 {
                self.dayOfMonth = dayOfMonth
            } else {
                return nil
            }
        } else {
            self.dayOfMonth = nil
        }

        // validate dayOfWeek
        if let dayOfWeek = dayOfWeek {
            if dayOfWeek >= 0 && dayOfWeek <= 6 {
                self.dayOfWeek = dayOfWeek
            } else {
                return nil
            }
        } else {
            self.dayOfWeek = nil
        }

        // validate hour
        if let hour = hour {
            if hour >= 0 && hour <= 23 {
                self.hour = hour
            } else {
                return nil
            }
        } else {
            self.hour = nil
        }

        // validate minute
        if let minute = minute {
            if minute >= 0 && minute <= 59 {
                self.minute = minute
            } else {
                return nil
            }
        } else {
            self.minute = nil
        }

        // validate second
        if let second = second {
            if second >= 0 && second <= 59 {
                self.second = second
            } else {
                return nil
            }
        } else {
            self.second = nil
        }
    }

    
}
