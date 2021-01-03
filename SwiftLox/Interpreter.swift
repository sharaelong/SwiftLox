//
//  Interpreter.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/03.
//

import Foundation

class Interpreter {
    private func isTruthy(object: AnyHashable?) -> Bool {
        guard let object = object else { return false }
        if let object = object as? Bool {
            return object
        }
        return true
    }

    private func isEqual(left: AnyHashable?, right: AnyHashable?) -> Bool {
        return left == right
    }

    private func checkNumberOperand(operator: Token, operand: AnyHashable?) throws {
        if operand is Double { return }
        throw RuntimeError(token: `operator`, message: "Operand must be a number.")
    }

    private func checkNumberOperands(operator: Token, left: AnyHashable?, right: AnyHashable?) throws {
        if left is Double && right is Double { return }
        throw RuntimeError(token: `operator`, message: "Operand must be numbers.")
    }

    private func stringify(object: AnyHashable?) -> String {
        guard let object = object else { return "nil" }
        if object is Double {
            let text = String(describing: object)
            return text.removingSuffix(".0")
        }
        return String(describing: object)
    }

    private func evaluate(expr: Expr) throws -> AnyHashable?  {
        switch expr {
        case .literal(let value):
            return value
        case .grouping(let expression):
            return try evaluate(expr: expression)
        case .unary(let `operator`, let right):
            let right = try evaluate(expr: right)
            switch `operator`.kind {
            case .minus:
                try checkNumberOperand(operator: `operator`, operand: right)
                return -(right as! Double)
            case .bang:
                return !isTruthy(object: right)
            default: fatalError()
            }
        case .binary(let left, let `operator`, let right):
            let left = try evaluate(expr: left)
            let right = try evaluate(expr: right)
            switch `operator`.kind {
            case .minus:
                try checkNumberOperands(operator: `operator`, left: left, right: right)
                return (left as! Double) - (right as! Double)
            case .slash:
                try checkNumberOperands(operator: `operator`, left: left, right: right)
                return (left as! Double) / (right as! Double)
            case .star:
                try checkNumberOperands(operator: `operator`, left: left, right: right)
                return (left as! Double) * (right as! Double)
            case .plus:
                if let left = left as? String, let right = right as? String {
                    return left + right
                } else if let left = left as? Double, let right = right as? Double {
                    return left + right
                } else {
                    throw RuntimeError.init(token: `operator`, message: "Operands must be two numbers or two strings")
                }
            case .greater:
                try checkNumberOperands(operator: `operator`, left: left, right: right)
                return (left as! Double) > (right as! Double)
            case .greaterEqual:
                try checkNumberOperands(operator: `operator`, left: left, right: right)
                return (left as! Double) >= (right as! Double)
            case .less:
                try checkNumberOperands(operator: `operator`, left: left, right: right)
                return (left as! Double) < (right as! Double)
            case .lessEqual:
                try checkNumberOperands(operator: `operator`, left: left, right: right)
                return (left as! Double) <= (right as! Double)
            case .bangEqual:
                return !isEqual(left: left, right: right)
            case .equalEqual:
                return isEqual(left: left, right: right)
            default: fatalError()
            }
        }
    }

    func interpret(expr: Expr) {
        do {
            try print(stringify(object: evaluate(expr: expr)))
        } catch {
            let error = error as! RuntimeError
            SwiftLox.runtimeError(error: error)
        }
    }
}
