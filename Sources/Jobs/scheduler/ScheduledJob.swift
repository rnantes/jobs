//
//  ScheduledJob.swift
//  App
//
//  Created by Reid Nantes on 2019-01-26.
//

import Foundation

public struct ScheduledJob {
    let job: Job
    let scheduleRule: RecurrenceRule

    public init(job: Job, scheduleRule: RecurrenceRule) {
        self.job = job
        self.scheduleRule = scheduleRule
    }
}
