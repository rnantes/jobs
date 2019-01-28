//
//  ScheduleEvaluationService.swift
//  App
//
//  Created by Reid Nantes on 2019-01-26.
//

import Foundation
import Vapor

/// A `Service` used to evalute 
public struct ScheduleEvaluationService: Service {

    internal var scheduledJobs = [ScheduledJob]()
    let calendar = Calendar.current

    public init() {}

    mutating public func add(_ scheduledJob: ScheduledJob) {
        scheduledJobs.append(scheduledJob)
    }

    func evaluateRuleTiming(currentState: EvaluationState, ruleTimes: Set<Int>, currentTiming: Int?) -> EvaluationState {
        guard let currentTiming = currentTiming else {
            return EvaluationState.failed
        }

        if ruleTimes.count > 0 {
            if ruleTimes.contains(currentTiming) {
                return EvaluationState.passing
            } else {
                return EvaluationState.failed
            }
        }

        return currentState
    }

    enum EvaluationState {
        case noComparisonAttempted
        case failed
        case passing
    }



    func evaluate(currentDateTime: Date, recurrenceRule: RecurrenceRule) -> Bool {

        var evaluationState = EvaluationState.noComparisonAttempted

        // seconds
        evaluationState = evaluateRuleTiming(currentState: evaluationState,
                                             ruleTimes: recurrenceRule.seconds,
                                             currentTiming: currentDateTime.second())
        if evaluationState == .failed { return false }

        // minutes
        evaluationState = evaluateRuleTiming(currentState: evaluationState,
                                             ruleTimes: recurrenceRule.minute,
                                             currentTiming: currentDateTime.minute())
        if evaluationState == .failed { return false }

        // hours
        evaluationState = evaluateRuleTiming(currentState: evaluationState,
                                             ruleTimes: recurrenceRule.hour,
                                             currentTiming: currentDateTime.hour())
        if evaluationState == .failed { return false }

        // dayOfWeek
        evaluationState = evaluateRuleTiming(currentState: evaluationState,
                                             ruleTimes: recurrenceRule.dayOfWeek,
                                             currentTiming: currentDateTime.dayOfWeek())
        if evaluationState == .failed { return false }

        // dayOfMonth
        evaluationState = evaluateRuleTiming(currentState: evaluationState,
                                             ruleTimes: recurrenceRule.dayOfMonth,
                                             currentTiming: currentDateTime.dayOfMonth())
        if evaluationState == .failed { return false }

        // month
        evaluationState = evaluateRuleTiming(currentState: evaluationState,
                                             ruleTimes: recurrenceRule.dayOfMonth,
                                             currentTiming: currentDateTime.month())

        // year
        evaluationState = evaluateRuleTiming(currentState: evaluationState,
                                             ruleTimes: recurrenceRule.year,
                                             currentTiming: currentDateTime.year())
        if evaluationState == .failed { return false }

        switch evaluationState {
        case.passing:
            return true
        case.failed:
            return false
        case.noComparisonAttempted:
            return false
        }
    }

    func evaluateStepConstraints(currentDateTime: Date, recurrenceRule: RecurrenceRule) {
        // TO DO
    }

}
