import Foundation

enum RecurrenceRuleError: Error {
    case atLeastOneRecurrenceRuleConstraintRequiredToIntialize
    case lowerBoundGreaterThanUpperBound
    case noSetConstraintForRecurrenceRuleTimeUnit
    case couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
    case noConstraintsSetForRecurrenceRule
    case coundNotResolveNextInstanceWithin1000Years
    case couldNotResolveYearConstraitFromDate
    case couldNotResloveNextValueFromConstraint
    case ruleInsatiable
    case couldNotParseHourAndMinuteFromString
    case startHourAndMinuteGreaterThanEndHourAndMinute
}

/// Defines the rule for when to run a job based on the given constraints
///
/// - warning: RecurrenceRule only supports the Gregorian calendar (i.e. Calendar.identifier.gregorian or Calendar.identifier.iso8601)
///
/// - Note: RecurrenceRule uses the local TimeZone as default
public struct RecurrenceRule {
    var timeZone: TimeZone

    private(set) var yearConstraint: YearRecurrenceRuleConstraint?
    private(set) var quarterConstraint: QuarterRecurrenceRuleConstraint?
    private(set) var monthConstraint: MonthRecurrenceRuleConstraint?
    private(set) var weekOfYearConstraint: WeekOfYearRecurrenceRuleConstraint?
    private(set) var weekOfMonthConstraint: WeekOfMonthRecurrenceRuleConstraint?
    private(set) var dayOfMonthConstraint: DayOfMonthRecurrenceRuleConstraint?
    private(set) var dayOfWeekConstraint: DayOfWeekRecurrenceRuleConstraint?
    private(set) var hourConstraint: HourRecurrenceRuleConstraint?
    private(set) var minuteConstraint: MinuteRecurrenceRuleConstraint?
    private(set) var secondConstraint: SecondRecurrenceRuleConstraint?

    private let recurrenceRuleTimeUnits: [RecurrenceRuleTimeUnit] = [
        .year,
        .quarter,
        .month,
        .weekOfYear,
        .weekOfMonth,
        .dayOfMonth,
        .dayOfWeek,
        .hour,
        .minute,
        .second
    ]

    init(timeZone: TimeZone = TimeZone.current) {
        self.timeZone = timeZone
    }

    init(yearConstraint: YearRecurrenceRuleConstraint? = nil,
         monthConstraint: MonthRecurrenceRuleConstraint? = nil,
         dayOfMonthConstraint: DayOfMonthRecurrenceRuleConstraint? = nil,
         dayOfWeekConstraint: DayOfWeekRecurrenceRuleConstraint? = nil,
         hourConstraint: HourRecurrenceRuleConstraint? = nil,
         minuteConstraint: MinuteRecurrenceRuleConstraint? = nil,
         secondConstraint: SecondRecurrenceRuleConstraint? = nil,
         timeZone: TimeZone = TimeZone.current) throws {
        self.timeZone = timeZone
        self.yearConstraint = yearConstraint
        self.monthConstraint = monthConstraint
        self.dayOfMonthConstraint = dayOfMonthConstraint
        self.dayOfWeekConstraint = dayOfWeekConstraint
        self.hourConstraint = hourConstraint
        self.minuteConstraint = minuteConstraint
        self.secondConstraint = secondConstraint
    }

    public mutating func setYearConstraint(_ yearConstraint: YearRecurrenceRuleConstraint) {
        self.yearConstraint = yearConstraint
    }

//    public mutating func setQuarterConstraint(quarterConstraint: QuarterRecurrenceRuleConstraint) {
//        self.quarterConstraint = quarterConstraint.constraint
//    }
//    public mutating func setWeekOfYearConstraint(weekOfYearConstraint: WeekOfYearRecurrenceRuleConstraint) {
//        self.weekOfYearConstraint = weekOfYearConstraint.constraint
//    }
//    public mutating func setWeekOfMonthConstraint(weekOfMonthConstraint: WeekOfMonthRecurrenceRuleConstraint) {
//        self.weekOfMonthConstraint = weekOfMonthConstraint.constraint
//    }

    public mutating func setMonthConstraint(_ monthConstraint: MonthRecurrenceRuleConstraint) {
        self.monthConstraint = monthConstraint
    }

    public mutating func setDayOfMonthConstraint(_ dayOfMonthConstraint: DayOfMonthRecurrenceRuleConstraint) {
        self.dayOfMonthConstraint = dayOfMonthConstraint
    }

    public mutating func setDayOfWeekConstraint(_ dayOfWeekConstraint: DayOfWeekRecurrenceRuleConstraint) {
        self.dayOfWeekConstraint = dayOfWeekConstraint
    }

    public mutating func setHourConstraint(_ hourConstraint: HourRecurrenceRuleConstraint) {
        self.hourConstraint = hourConstraint
    }

    public mutating func setMinuteConstraint(_ minuteConstraint: MinuteRecurrenceRuleConstraint) {
        self.minuteConstraint = minuteConstraint
    }

    public mutating func setSecondConstraint(_ secondConstraint: SecondRecurrenceRuleConstraint) {
        self.secondConstraint = secondConstraint
    }

    ///  Sets the timeZone used by rule constraintss
    ///
    /// - Parameter timeZone: The TimeZone constraints reference against
    public mutating func usingTimeZone(_ timeZone: TimeZone) {
        self.timeZone = timeZone
    }

    /// Evaluates if the constraints are satified at a given date
    ///
    /// - Parameter date: The date to test the constraints against
    /// - Returns: returns true if all constraints are satisfied for the given date
    public func evaluate(date: Date) throws -> Bool {
        return try evaluate(date: date).isValid
    }

    // Iterates through constraints to deterine if they are satisfied
    private func evaluate(date: Date) throws -> (isValid: Bool, ruleTimeUnitFailedOn: RecurrenceRuleTimeUnit?) {
        var ruleEvaluationState = EvaluationState.noComparisonAttempted
        var ruleTimeUnitFailedOn: RecurrenceRuleTimeUnit?

        for ruleTimeUnit in recurrenceRuleTimeUnits {
            guard let dateComponentValue = date.dateComponentValue(for: ruleTimeUnit, atTimeZone: timeZone) else {
                throw RecurrenceRuleError.couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
            }

            if let specificConstraint = resolveSpecificConstraint(ruleTimeUnit) {
                // evaluate the constraints
                let constraintEvalutionState = specificConstraint.evaluate(dateComponentValue)

                if constraintEvalutionState != .noComparisonAttempted {
                    ruleEvaluationState = constraintEvalutionState
                }
            } else {
                // constraint not set
                let lowestCadence = resolveLowestCadence()
                let lowestCadenceLevel = resolveCadenceLevel(lowestCadence)
                let currentConstraintCadenceLevel = resolveCadenceLevel(ruleTimeUnit)

                /// If second, minute, hour, dayOfMonth or month constraints are not set
                /// they must be at their default values to avoid rule passing on every second
                if (currentConstraintCadenceLevel <= lowestCadenceLevel) {
                    if ruleTimeUnit == .second && dateComponentValue != 0 {
                        ruleEvaluationState = .failed
                    } else if ruleTimeUnit == .minute && dateComponentValue != 0 {
                        ruleEvaluationState = .failed
                    } else if ruleTimeUnit == .hour && dateComponentValue != 0 {
                        ruleEvaluationState = .failed
                    } else if ruleTimeUnit == .dayOfMonth && dateComponentValue != 1 {
                        ruleEvaluationState = .failed
                    } else if ruleTimeUnit == .month && dateComponentValue != 1 {
                        ruleEvaluationState = .failed
                    }
                }
            }

            if ruleEvaluationState == .failed {
                // break  iteraton
                ruleTimeUnitFailedOn = ruleTimeUnit
                break
            }
        }

        if ruleEvaluationState == .passing {
            return (isValid: true, ruleTimeUnitFailedOn)
        } else {
            return (isValid: false, ruleTimeUnitFailedOn)
        }
    }

    /// Finds the next date from the starting date that satisfies the rule
    ///
    /// - Warning: The search is exhausted after the year 3000
    ///
    /// - Parameter date: The starting date
    /// - Returns: The next date that satisfies the rule
    public func resolveNextDateThatSatisfiesRule(date: Date) throws -> Date {
        guard let timeUnitOfLowestActiveConstraint = resolveTimeUnitOfActiveConstraintWithLowestCadenceLevel() else {
            throw RecurrenceRuleError.noConstraintsSetForRecurrenceRule
        }

        // throws error if rule contains constraints that can never be satisfiedss
        try checkForInsatiableConstraints()

        var dateToTest = date.dateByIncrementing(timeUnitOfLowestActiveConstraint)

        var isNextInstanceFound = false
        var isSearchExhausted = false
        var numOfChecksMade = 0
        while isNextInstanceFound == false && isSearchExhausted == false {
            guard let currentDateToTest = dateToTest else {
                throw RecurrenceRuleError.coundNotResolveNextInstanceWithin1000Years
            }
            if try isYearConstraintPossible(date: currentDateToTest) == false {
                throw RecurrenceRuleError.coundNotResolveNextInstanceWithin1000Years
            }

            if let ruleTimeUnitFailedOn = try self.evaluate(date: currentDateToTest).ruleTimeUnitFailedOn {
                let nextValidValue = try resolveNextValidValue(for: ruleTimeUnitFailedOn, date: currentDateToTest)
                dateToTest = try currentDateToTest.nextDate(where: ruleTimeUnitFailedOn, is: nextValidValue, atTimeZone: timeZone)

                // check if year of dateToTest is greater than the limit
                if let year = dateToTest?.year() {
                    if year > 3000 {
                        isSearchExhausted = true
                    }
                }
                numOfChecksMade += 1
            } else {
                isNextInstanceFound = true
            }
        }

        if isNextInstanceFound {
            if let nextDate = dateToTest {
                return nextDate
            } else {
                throw RecurrenceRuleError.coundNotResolveNextInstanceWithin1000Years
            }
        } else {
            throw RecurrenceRuleError.coundNotResolveNextInstanceWithin1000Years
        }
    }

    /// throws error if rule contains constraints that can never be satisfiedss
    private func checkForInsatiableConstraints() throws {
        // January, March, May, July, August, October, December
        let monthsWithExactly31Days = [1, 3, 5, 7, 8, 10, 12]
        // April, June, September, November
        let monthsWithExactly30Days = [4, 6, 9, 11]
        // februrary has 28 or 29 days

        guard let dayOfMonthLowestPossibleValue = dayOfMonthConstraint?.lowestPossibleValue else {
            return
        }

        if dayOfMonthLowestPossibleValue > 30 {
            var hasAtLeastOneMonthWith31Days = false
            if let monthConstraint = monthConstraint {
                for month in monthsWithExactly31Days {
                    if monthConstraint.evaluate(month) == .passing {
                        hasAtLeastOneMonthWith31Days = true
                    }
                }
            }

            if hasAtLeastOneMonthWith31Days == false {
                throw RecurrenceRuleError.ruleInsatiable
            }
        } else if dayOfMonthLowestPossibleValue > 29 {
            var hasOneMonthWithAtLeast30Days = false

            if let monthConstraint = monthConstraint {
                for month in monthsWithExactly31Days {
                    if monthConstraint.evaluate(month) == .passing {
                        hasOneMonthWithAtLeast30Days = true
                    }
                }
                for month in monthsWithExactly30Days {
                    if monthConstraint.evaluate(month) == .passing {
                        hasOneMonthWithAtLeast30Days = true
                    }
                }
            }

            if hasOneMonthWithAtLeast30Days == false {
                throw RecurrenceRuleError.ruleInsatiable
            }
        }
    }

    private func resolveTimeUnitOfActiveConstraintWithLowestCadenceLevel() -> RecurrenceRuleTimeUnit? {
        var activeConstraintTimeUnitWithLowestCadenceLevel: RecurrenceRuleTimeUnit?

        for ruleTimeUnit in recurrenceRuleTimeUnits {
            let constraint = resolveSpecificConstraint(ruleTimeUnit)
            if constraint != nil {
                activeConstraintTimeUnitWithLowestCadenceLevel = ruleTimeUnit
            }
        }

        return activeConstraintTimeUnitWithLowestCadenceLevel
    }

    private func resolveNextValidValue(for ruleTimeUnit: RecurrenceRuleTimeUnit, date: Date) throws -> Int {
        guard let currentValue = date.dateComponentValue(for: ruleTimeUnit, atTimeZone: timeZone) else {
            throw RecurrenceRuleError.couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
        }

        if let specificConstraint = resolveSpecificConstraint(ruleTimeUnit) {
            guard let nextValidValue = specificConstraint.nextValidValue(currentValue: currentValue) else {
                throw RecurrenceRuleError.couldNotResloveNextValueFromConstraint
            }

            return nextValidValue
        } else {
            throw RecurrenceRuleError.couldNotResloveNextValueFromConstraint
        }

    }

    // get a specificConstraint by its RecurrenceRuleTimeUnit
    private func resolveSpecificConstraint(_ ruleTimeUnit: RecurrenceRuleTimeUnit) -> SpecificRecurrenceRuleConstraint? {
        switch ruleTimeUnit {
        case .second:
            return self.secondConstraint
        case .minute:
            return self.minuteConstraint
        case .hour:
            return self.hourConstraint
        case .dayOfWeek:
            return self.dayOfWeekConstraint
        case .dayOfMonth:
            return self.dayOfMonthConstraint
        case .weekOfMonth:
            return self.weekOfMonthConstraint
        case .weekOfYear:
            return self.weekOfYearConstraint
        case .month:
            return self.monthConstraint
        case .quarter:
            return self.quarterConstraint
        case .year:
            return self.yearConstraint
        }
    }

    private func resolveLowestCadence() -> RecurrenceRuleTimeUnit {
        if secondConstraint != nil {
            return .second
        } else if minuteConstraint != nil {
            return .minute
        } else if hourConstraint != nil {
            return .hour
        } else if dayOfMonthConstraint != nil {
            return .dayOfMonth
        } else if monthConstraint != nil {
            return .month
        } else {
            return .year
        }
    }

    private func resolveCadenceLevel(_ ruleTimeUnit: RecurrenceRuleTimeUnit) -> Int {
        switch ruleTimeUnit {
        case .second:
            return 0
        case .minute:
            return 1
        case .hour:
            return 2
        case .dayOfMonth:
            return 3
        case .month:
            return 4
        default:
            return 6
        }
    }

    private func isYearConstraintPossible(date: Date) throws -> Bool {
        guard let currentYear = date.year() else {
            throw RecurrenceRuleError.couldNotResolveYearConstraitFromDate
        }

        if let yearConstraint = yearConstraint {
            if let higestPossibleYearValue = yearConstraint.highestPossibleValue {
                if currentYear < higestPossibleYearValue {
                    return true
                }
            } else {
                return true
            }

            return false
        } else {
            return true
        }
    }

}
