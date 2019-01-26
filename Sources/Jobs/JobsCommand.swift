import Foundation
import Vapor
import NIO

/// The command to start the Queue job
public class JobsCommand: Command {

    let jobScheduler = JobScheduler()

    /// See `Command`.`arguments`
    public var arguments: [CommandArgument] = []

    /// See `Command`.`options`
    public var options: [CommandOption] {
        return [
            CommandOption.value(name: "queue")
        ]
    }

    private var isShuttingDown: Bool {
        get {
            self._lock.lock()
            defer { self._lock.unlock() }
            return self._isShuttingDown
        }
        set {
            self._lock.lock()
            defer { self._lock.unlock() }
            self._isShuttingDown = newValue
        }
    }

    private var _isShuttingDown: Bool = false
    private var _lock: NSLock

    /// See `Command`.`help`
    public var help: [String] = ["Rugetgetns queued worker jobs"]

    /// Creates a new `JobCommand`
    public init() {
        _lock = NSLock()
    }

    /// See `Command`.`run(using:)`
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        print("HERE1")
        print("System.coreCount: \(System.coreCount)")

        let elg = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let signalQueue = DispatchQueue(label: "vapor.jobs.command.SignalHandlingQueue")

        //SIGTERM
        let termSignalSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: signalQueue)
        termSignalSource.setEventHandler {
            print("Shutting down remaining jobs.")
            self.isShuttingDown = true
            termSignalSource.cancel()
        }
        signal(SIGTERM, SIG_IGN)
        termSignalSource.resume()

        //SIGINT
        let intSignalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: signalQueue)
        intSignalSource.setEventHandler {
            print("Shutting down remaining jobs.")
            self.isShuttingDown = true
            intSignalSource.cancel()
        }
        signal(SIGINT, SIG_IGN)
        intSignalSource.resume()

        print("here 2")

        var shutdownPromises: [EventLoopPromise<Void>] = []

        var i = 0
        for eventLoop in elg.makeIterator()! {
            let sub = context.container.subContainer(on: eventLoop)
            let console = context.console
            let queueName = context.options["queue"] ?? QueueType.default.name
            let shutdownPromise: EventLoopPromise<Void> = eventLoop.newPromise()
            shutdownPromises.append(shutdownPromise)

            if i == 0 {
                eventLoop.submit {
                    try self.jobScheduler.scheduleTask(eventLoop: eventLoop,
                                                       container: sub,
                                                       console: console)
                    }.catch {
                        console.error("Could not boot EventLoop: \($0)")
                }
            } else {
                eventLoop.submit {
                    try self.setupTask(eventLoopID: i,
                                       eventLoop: eventLoop,
                                       container: sub,
                                       queueName: queueName,
                                       console: console,
                                       promise: shutdownPromise)
                    }.catch {
                        console.error("Could not boot EventLoop: \($0)")
                }
            }
            i += 1
        }

        print("here 3")

        return .andAll(shutdownPromises.map { $0.futureResult }, eventLoop: elg.next())
    }


    // sets up
    private func setupTask(eventLoopID: Int,
                           eventLoop: EventLoop,
                           container: SubContainer,
                           queueName: String,
                           console: Console,
                           promise: EventLoopPromise<Void>) throws
    {
        let queue = QueueType(name: queueName)
        let queueService = try container.make(QueueService.self)
        let jobContext = (try? container.make(JobContext.self)) ?? JobContext()
        let key = queue.makeKey(with: queueService.persistenceKey)
        let config = try container.make(JobsConfig.self)

        print("setupTask - \(eventLoopID)")

        _ = eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: queueService.refreshInterval) { task -> EventLoopFuture<Void> in
            return queueService.persistenceLayer.get(key: key, jobsConfig: config).flatMap { jobData in

                //Check if shutting down
                if self.isShuttingDown {
                    task.cancel()
                    promise.succeed()
                }

                //No job found, go to the next iteration
                guard let jobData = jobData else {
                    print("NO Job: \(eventLoopID)")
                    return eventLoop.future()
                }
                print("Job FOUND: \(eventLoopID)")


                // job is found, dequeue
                let job = jobData.data
                console.info("Dequeing Job \(jobData.id)", newLine: true)

                let futureJob = job.dequeue(context: jobContext, worker: eventLoop)
                return self.firstFutureToSucceed(future: futureJob, tries: jobData.maxRetryCount, on: eventLoop)
                    .flatMap { _ in
                        guard let jobString = job.stringValue(key: key, maxRetryCount: jobData.maxRetryCount, id: jobData.id) else {
                            return eventLoop.future(error: Abort(.internalServerError))
                        }

                        return queueService.persistenceLayer.completed(key: key, jobString: jobString)
                    }
                    .catchFlatMap { error in
                        console.error("[\(jobData.id)] Error: \(error)", newLine: true)

                        guard let jobString = job.stringValue(key: key, maxRetryCount: jobData.maxRetryCount, id: jobData.id) else {
                            return eventLoop.future(error: Abort(.internalServerError))
                        }

                        return queueService
                            .persistenceLayer
                            .completed(key: key, jobString: jobString)
                            .flatMap { _ in
                                return job.error(context: jobContext, error: error, worker: eventLoop)
                        }
                }
            }
        }
    }

    /// Returns the first time a given future succeeds and is under the `tries`
    ///
    /// - Parameters:
    ///   - future: The future to run recursively
    ///   - tries: The number of tries to execute this future before returning a failure
    ///   - worker: An `EventLoopGroup` that can be used to generate future values
    /// - Returns: The completed future, with or without an error
    private func firstFutureToSucceed<T>(future: Future<T>, tries: Int, on worker: EventLoopGroup) -> Future<T> {
        return future.map { complete in
            return complete
            }.catchFlatMap { error in
                if tries == 0 {
                    return worker.future(error: error)
                } else {
                    return self.firstFutureToSucceed(future: future, tries: tries - 1, on: worker)
                }
        }
    }
}
