//
//  RecurrenceTimeAmount.swift
//  App
//
//  Created by Reid Nantes on 2019-01-26.
//

import Foundation

public struct ScheduleTimeAmount {
    /// The seconds representation of the `ScheduleTimeAmount`.
    public let seconds: Int


    private init(_ seconds: Int) {
        self.seconds = seconds
    }

    func seconds(_ amount: Int) -> ScheduleTimeAmount {
        return ScheduleTimeAmount(amount)
    }

    func minutes(_ amount: Int) -> ScheduleTimeAmount{
        return ScheduleTimeAmount(amount * 60)
    }

    func hours(_ amount: Int) -> ScheduleTimeAmount {
        return ScheduleTimeAmount(amount * 60 * 60)
    }

    func days(_ amount: Int) -> ScheduleTimeAmount {
        return ScheduleTimeAmount(amount * 60 * 60 * 24)
    }

    func weeks(_ amount: Int) -> ScheduleTimeAmount {
        return ScheduleTimeAmount(amount * 60 * 60 * 24 * 7)
    }

    func months(_ amount: Int) -> ScheduleTimeAmount {
        return ScheduleTimeAmount(amount * 60 * 60 * 24 * 7)
    }

    func years(_ amount: Int) -> ScheduleTimeAmount {
        return ScheduleTimeAmount(amount * 60 * 60 * 24 * 7 * 365)
    }
}
