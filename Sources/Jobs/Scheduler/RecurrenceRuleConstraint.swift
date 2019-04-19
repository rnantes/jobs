import Foundation

enum RecurrenceRuleConstraintError: Error {
    case constraintAmountLessThanLowerBound
    case constraintAmountGreaterThanUpperBound
}

public enum EvaluationState {
    case noComparisonAttempted
    case failed
    case passing
}


struct ConstraintValueValidator {
    func validate(value: Int, validLowerBound: Int?, validUpperBound: Int?) throws {
        if let lowerBound = validLowerBound {
            if value < lowerBound {
                throw RecurrenceRuleConstraintError.constraintAmountLessThanLowerBound
            }
        }

        if let upperBound = validUpperBound {
            if value > upperBound {
                throw RecurrenceRuleConstraintError.constraintAmountGreaterThanUpperBound
            }
        }
    }
}

protocol RecurrenceRuleConstraint {
    var validLowerBound: Int? { get }
    var validUpperBound: Int? { get }
    var lowestPossibleValue: Int? { get }
    var highestPossibleValue: Int? { get }

    func evaluate(_ evaluationAmount: Int) -> EvaluationState
    func nextValidValue(currentValue: Int) -> Int?
}

struct RecurrenceRuleSetConstraint: RecurrenceRuleConstraint {
    let validLowerBound: Int?
    let validUpperBound: Int?
    let setConstraint: Set<Int>

    var lowestPossibleValue: Int? {
        if var lowest = setConstraint.first {
            for value in setConstraint {
                if value < lowest {
                    lowest = value
                }
            }
            return lowest
        } else {
            return nil
        }
    }

    var highestPossibleValue: Int? {
        if var highest = setConstraint.first {
            for value in setConstraint {
                if value > highest {
                    highest = value
                }
            }
            return highest
        } else {
            return nil
        }
    }

    init (timeUnit: RecurrenceRuleTimeUnit, setConstraint: Set<Int> = Set<Int>()) throws {
        let validLowerBound = Calendar.gregorianLowerBound(for: timeUnit)
        let validUpperBound = Calendar.gregorianUpperBound(for: timeUnit)
        try self.init(validLowerBound: validLowerBound, validUpperBound: validUpperBound, setConstraint: setConstraint)
    }

    init(validLowerBound: Int?, validUpperBound: Int?) {
        self.validLowerBound = validLowerBound
        self.validUpperBound = validUpperBound
        self.setConstraint = Set<Int>()
    }

    init(validLowerBound: Int?, validUpperBound: Int?, setConstraint: Set<Int> = Set<Int>()) throws {
        self.validLowerBound = validLowerBound
        self.validUpperBound = validUpperBound

        let validator = ConstraintValueValidator()
        for amount in setConstraint {
            try validator.validate(value: amount, validLowerBound: validLowerBound, validUpperBound: validUpperBound)
        }
        self.setConstraint = setConstraint
    }

    init(from constraintToCopy: RecurrenceRuleConstraint, setConstraint: Set<Int> = Set<Int>()) throws {
        self.validLowerBound = constraintToCopy.validLowerBound
        self.validUpperBound = constraintToCopy.validUpperBound

        let validator = ConstraintValueValidator()
        for amount in setConstraint {
            try validator.validate(value: amount, validLowerBound: validLowerBound, validUpperBound: validUpperBound)
        }
        self.setConstraint = setConstraint
    }

    /// Evaluates if a given amount satisfies the constraint
    ///
    /// - Parameter evaluationAmount: The amount to test
    /// - Returns: passing, failed, or noComparisonAttempted
    public func evaluate(_ evaluationAmount: Int) -> EvaluationState {
        if setConstraint.contains(evaluationAmount) {
            return EvaluationState.passing
        } else {
            return EvaluationState.failed
        }
    }

    /// Finds the the next value that satisfies the constraint
    ///
    /// - Parameter currentValue: The current value the date component
    /// - Returns: The next value that satisfies the constraint
    public func nextValidValue(currentValue: Int) -> Int? {
        var lowestValueGreaterThanCurrentValue: Int?

        for value in setConstraint {
            if value >= currentValue {
                if let low = lowestValueGreaterThanCurrentValue {
                    if value < low {
                        lowestValueGreaterThanCurrentValue = value
                    }
                } else {
                    lowestValueGreaterThanCurrentValue = value
                }
            }
        }

        if lowestValueGreaterThanCurrentValue != nil {
            return lowestValueGreaterThanCurrentValue
        } else {
            return lowestPossibleValue
        }
    }
}

struct RecurrenceRuleRangeConstraint: RecurrenceRuleConstraint {
    let validLowerBound: Int?
    let validUpperBound: Int?
    let rangeConstraint: ClosedRange<Int>

    var lowestPossibleValue: Int? {
        return rangeConstraint.lowerBound
    }

    var highestPossibleValue: Int? {
        return rangeConstraint.upperBound
    }

    init(timeUnit: RecurrenceRuleTimeUnit, rangeConstraint: ClosedRange<Int>) throws {
        let validLowerBound = Calendar.gregorianLowerBound(for: timeUnit)
        let validUpperBound = Calendar.gregorianUpperBound(for: timeUnit)
        try self.init(validLowerBound: validLowerBound, validUpperBound: validUpperBound, rangeConstraint: rangeConstraint)
    }

    init(validLowerBound: Int?, validUpperBound: Int?, rangeConstraint: ClosedRange<Int>) throws {
        self.validLowerBound = validLowerBound
        self.validUpperBound = validUpperBound

        let validator = ConstraintValueValidator()
        try validator.validate(value: rangeConstraint.lowerBound, validLowerBound: validLowerBound, validUpperBound: validUpperBound)
        try validator.validate(value: rangeConstraint.upperBound, validLowerBound: validLowerBound, validUpperBound: validUpperBound)
        self.rangeConstraint = rangeConstraint
    }

    /// Evaluates if a given amount satisfies the constraint
    ///
    /// - Parameter evaluationAmount: The amount to test
    /// - Returns: passing, failed, or noComparisonAttempted
    public func evaluate(_ evaluationAmount: Int) -> EvaluationState {
        if rangeConstraint.contains(evaluationAmount) {
            return EvaluationState.passing
        } else {
            return EvaluationState.failed
        }
    }

    /// Finds the the next value that satisfies the constraint
    ///
    /// - Parameter currentValue: The current value the date component
    /// - Returns: The next value that satisfies the constraint
    public func nextValidValue(currentValue: Int) -> Int? {
        var lowestValueGreaterThanCurrentValue: Int?

        if (currentValue + 1) <= rangeConstraint.upperBound {
            if let low = lowestValueGreaterThanCurrentValue {
                if low >= (currentValue + 1) {
                    lowestValueGreaterThanCurrentValue = (currentValue + 1)
                }
            } else {
                lowestValueGreaterThanCurrentValue = (currentValue + 1)
            }
        }

        if lowestValueGreaterThanCurrentValue != nil {
            return lowestValueGreaterThanCurrentValue
        } else {
            return lowestPossibleValue
        }
    }

}

struct RecurrenceRuleStepConstraint: RecurrenceRuleConstraint {
    let validLowerBound: Int?
    let validUpperBound: Int?
    let stepConstraint: Int

    var lowestPossibleValue: Int? {
        return 0
    }

    var highestPossibleValue: Int? {
        return nil
    }

    init(timeUnit: RecurrenceRuleTimeUnit, stepConstraint: Int) throws {
        let validLowerBound = Calendar.gregorianLowerBound(for: timeUnit)
        let validUpperBound = Calendar.gregorianUpperBound(for: timeUnit)
        try self.init(validLowerBound: validLowerBound, validUpperBound: validUpperBound, stepConstraint: stepConstraint)
    }

    init(validLowerBound: Int?, validUpperBound: Int?, stepConstraint: Int) throws  {
        self.validLowerBound = validLowerBound
        self.validUpperBound = validUpperBound
        if stepConstraint < 1 {
            throw RecurrenceRuleConstraintError.constraintAmountLessThanLowerBound
        }
        if let validUpperBound = validUpperBound {
            if stepConstraint < 1 {
                throw RecurrenceRuleConstraintError.constraintAmountLessThanLowerBound
            }
            if stepConstraint > validUpperBound {
                throw RecurrenceRuleConstraintError.constraintAmountGreaterThanUpperBound
            }
        }

        self.stepConstraint = stepConstraint
    }

    /// Evaluates if a given amount satisfies the constraint
    ///
    /// - Parameter evaluationAmount: The amount to test
    /// - Returns: passing, failed, or noComparisonAttempted
    public func evaluate(_ evaluationAmount: Int) -> EvaluationState {
        // pass if evaluationAmount is divisiable of stepConstriant
        if evaluationAmount % stepConstraint == 0 {
            return EvaluationState.passing
        } else {
            return EvaluationState.failed
        }
    }

    /// Finds the the next value that satisfies the constraint
    ///
    /// - Parameter currentValue: The current value the date component
    /// - Returns: The next value that satisfies the constraint
    public func nextValidValue(currentValue: Int) -> Int? {
        var lowestValueGreaterThanCurrentValue: Int?

        // step
        var multiple = 0
        var shouldStopLooking = false

        if let validUpperBound = validUpperBound {
            // others
            var shouldStopLooking = false
            while multiple <= validUpperBound && shouldStopLooking == false {
                if multiple >= currentValue {
                    if let low = lowestValueGreaterThanCurrentValue {
                        if multiple < low {
                            lowestValueGreaterThanCurrentValue = multiple
                        }
                    } else {
                        lowestValueGreaterThanCurrentValue = multiple
                    }
                    shouldStopLooking = true
                }
                multiple = multiple + stepConstraint
            }
        } else {
            // year
            while shouldStopLooking == false {
                if multiple >= currentValue {
                    if let low = lowestValueGreaterThanCurrentValue {
                        if multiple < low {
                            lowestValueGreaterThanCurrentValue = multiple
                        }
                    } else {
                        lowestValueGreaterThanCurrentValue = multiple
                    }
                    shouldStopLooking = true
                }

                multiple = multiple + stepConstraint
            }
        }

        if lowestValueGreaterThanCurrentValue != nil {
            return lowestValueGreaterThanCurrentValue
        } else {
            return lowestPossibleValue
        }
    }

}
