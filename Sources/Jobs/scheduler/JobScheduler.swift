//
//  JobScheduler.swift
//  App
//
//  Created by Reid Nantes on 2019-01-26.
//

import Foundation
import Vapor
import NIO

public struct JobScheduler {

    let refreshInterval = TimeAmount.seconds(1);


    // loops taks
    func scheduleTask(eventLoop: EventLoop, container: SubContainer, console: Console) throws {
        var i = 0

        let scheduleEvaluationService = try container.make(ScheduleEvaluationService.self)
//        let queueService = try container.make(QueueService.self)

         _ = eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: refreshInterval) { task -> EventLoopFuture<Void> in

            let currentDateTime = Date()

            // evaluate rules
            print("i:\(i)  \(currentDateTime.second()!)/60sec")


            for scheduledJob in scheduleEvaluationService.scheduledJobs {
                if scheduleEvaluationService.evaluate(currentDateTime: currentDateTime, recurrenceRule: scheduledJob.scheduleRule) {
                    print("Schedule rule hit")
                    //queueService.dispatch(job: scheduledJob.job, maxRetryCount: 10)
                } else {
                    print("wait...")
                }
            }

            i += 1
            return eventLoop.future()
        }
            
    }
}
