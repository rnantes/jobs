//
//  ReccurrenceRules.swift
//  App
//
//  Created by Reid Nantes on 2019-01-26.
//

import Foundation

enum RecurrenceRuleError: Error {
    case secondNotBetweenZeroAndFiftyNine
}

public class RecurrenceRule {
    let referenceDate: Date

    // single or list of values
    var year = Set<Int>()
    var month = Set<Int>()
    var dayOfMonth = Set<Int>()
    var dayOfWeek = Set<Int>()
    var hour =  Set<Int>()
    var minute = Set<Int>()
    var seconds = Set<Int>()

    // step values
    var yearStep: Int? = nil
    var monthStep: Int? = nil
    var weekStep: Int? = nil
    var dayStep: Int? = nil
    var hourStep: Int? = nil
    var minuteStep: Int? = nil
    var secondStep: Int? = nil

    // rangeValues

    // year (>1)
    // month (1-12) ex: 1 january, 12 December
    // dayOfMonth (1-31) ex: 1 1st of month, 31 31st of month
    // dayOfWeek (0-6) ex: 0 sunday, 6 saturday
    // hour: Int (0-23)
    // minute: Int (0-59)
    // second: Int (0-59)

    public init() {
        self.referenceDate = Date()
    }

    public func every(_ timeAmount: ScheduleTimeAmount) -> Self {
        switch timeAmount.timeUnit {
        case .second:
            self.secondStep = timeAmount.amount
        case .minute:
            self.minuteStep = timeAmount.amount
        case .hour:
            self.hourStep = timeAmount.amount
        case .day:
            self.dayStep = timeAmount.amount
        case .week:
            self.weekStep = timeAmount.amount
        case .month:
            self.monthStep = timeAmount.amount
        case .year:
            self.yearStep = timeAmount.amount
        }

        return self
    }

    public func atSecond(_ second: Int) throws -> Self {
        if second >= 0 && second <= 59 {
            self.seconds.insert(second)
        } else {
            throw RecurrenceRuleError.secondNotBetweenZeroAndFiftyNine
        }

        return self
    }

    public func atMinute(_ minute: Int) throws -> Self {
        if minute >= 0 && minute <= 59 {
            self.minute.insert(minute)
        } else {
            throw RecurrenceRuleError.secondNotBetweenZeroAndFiftyNine
        }

        return self
    }

    public func atHour(_ hour: Int) throws -> Self {
        if hour >= 0 && hour <= 23 {
            self.hour.insert(hour)
        } else {
            throw RecurrenceRuleError.secondNotBetweenZeroAndFiftyNine
        }

        return self
    }

    public func atDayOfWeek(_ dayOfWeek: Int) throws -> Self {
        if dayOfWeek >= 0 && dayOfWeek <= 6 {
            self.dayOfWeek.insert(dayOfWeek)
        } else {
            throw RecurrenceRuleError.secondNotBetweenZeroAndFiftyNine
        }

        return self
    }

    public func atDayOfMonth(_ dayOfMonth: Int) throws -> Self {
        if dayOfMonth >= 1 && dayOfMonth <= 31 {
           self.dayOfMonth.insert(dayOfMonth)
        } else {
            throw RecurrenceRuleError.secondNotBetweenZeroAndFiftyNine
        }

        return self
    }

    public func atMonth(_ month: Int) throws -> Self {
        if month >= 1 && month <= 12 {
            self.month.insert(month)
        } else {
            throw RecurrenceRuleError.secondNotBetweenZeroAndFiftyNine
        }

        return self
    }

    public func atYear(_ year: Int) throws -> Self {
        if year > 0 {
            self.year.insert(year)
        } else {
            throw RecurrenceRuleError.secondNotBetweenZeroAndFiftyNine
        }

        return self
    }

    public func atSeconds(_ seconds: [Int]) throws -> Self {
        for second in seconds {
            _ = try atSecond(second)
        }

        return self
    }

    public func atMinutes(_ minutes: [Int]) throws -> Self {
        for minute in minutes {
            _ = try atMinute(minute)
        }

        return self
    }

    public func atHours(_ hours: [Int]) throws -> Self {
        for hour in hours {
            _ = try atHour(hour)
        }

        return self
    }

    public func atDaysOfWeek(_ daysOfWeek: [Int]) throws -> Self {
        for dayOfWeek in daysOfWeek {
            _ = try atDayOfWeek(dayOfWeek)
        }

        return self
    }

    public func atDaysOfMonth(_ daysOfMonth: [Int]) throws -> Self {
        for dayOfMonth in daysOfMonth {
            _ = try atDayOfMonth(dayOfMonth)
        }

        return self
    }

    public func atMonths(_ months: [Int]) throws -> Self {
        for month in months {
            _ = try atMonth(month)
        }

        return self
    }

    public func atYear(_ years: [Int]) throws -> Self {
        for year in years {
            _ = try atYear(year)
        }

        return self
    }
}
