//
//  JobScheduler.swift
//  App
//
//  Created by Reid Nantes on 2019-01-26.
//

import Foundation
import Vapor
import NIO

struct JobScheduler {

    let refreshInterval = TimeAmount.seconds(1);

    let rules: [RecurrenceRule] = [RecurrenceRule.init(second: 30)!, RecurrenceRule.init(second: 15)!]


    // loops taks
    func scheduleTask(eventLoop: EventLoop, container: SubContainer, console: Console) throws {
        let scheduleEvaluationService = try container.make(ScheduleEvaluationService.self)

         _ = eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: refreshInterval) { task -> EventLoopFuture<Void> in

            let currentDateTime = Date()

            // evaluate rules
            for rule in self.rules {
                print("testSchedule")
                if scheduleEvaluationService.evaluate(currentDateTime: currentDateTime, recurrenceRule: rule) {
                    print("Schedule rule hit")
                } else {
                    print("wait...")
                }
            }

            return eventLoop.future()
        }
            
    }
}
