//
//  ScheduleEvaluationService.swift
//  App
//
//  Created by Reid Nantes on 2019-01-26.
//

import Foundation
import Vapor

/// A `Service` used to evalute 
struct ScheduleEvaluationService: Service {

    func evaluate(currentDateTime: Date, recurrenceRule: RecurrenceRule) -> Bool {
        let calendar = Calendar.current


        let time = calendar.dateComponents([.second], from: currentDateTime)

        if let ruleSecond = recurrenceRule.second {
            if let second = time.second {
                if second == ruleSecond {
                    return true
                }
            }
        }


        return false
    }
}
