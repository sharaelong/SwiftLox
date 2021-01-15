//
//  Interpreter.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/03.
//

import Foundation

class Interpreter {
    let globals = Environment()
    private var environment: Environment
    private var locals: [Expr : Int] = [:]

    init() {
        environment = globals
        globals.define(name: "clock", value: ClockFunction())
    }

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

    func resolve(expr: Expr, depth: Int) {
        locals[expr] = depth
    }

    private func lookUpVariable(name: Token, expr: Expr) throws -> AnyHashable? {
        let distance = locals[expr]
        if let distance = distance {
            return environment.getAt(distance: distance, name: String(name.lexeme))
        } else {
            return try globals.get(name: name)
        }
    }

    @discardableResult private func evaluate(expr: Expr) throws -> AnyHashable?  {
        switch expr {
        case .literal(let value):
            return value
        case .grouping(let expression):
            return try evaluate(expr: expression)
        case .call(let callee, let paren, let arguments):
            let callee = try evaluate(expr: callee)

            var argumentList: [AnyHashable?] = []
            for argument in arguments {
                argumentList.append(try evaluate(expr: argument))
            }

            guard let function = callee as? LoxCallable else {
                throw RuntimeError(token: paren, message: "Can only call functions and classes.")
            }
            if argumentList.count != function.arity() {
                throw RuntimeError(token: paren, message: "Expected \(function.arity()) arguments but got \(argumentList.count).")
            }
            return try function.call(interpreter: self, arguments: argumentList)
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
        case .logical(let left, let `operator`, let right):
            let left = try evaluate(expr: left)
            if `operator`.kind == .or && isTruthy(object: left) {
                return left
            } else if `operator`.kind == .and && !isTruthy(object: left) {
                return left
            }
            return try evaluate(expr: right)
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
        case .variable(let name):
            return try lookUpVariable(name: name, expr: expr)
        case .assign(let name, let value):
            let value = try evaluate(expr: value)
            let distance = locals[expr]
            if let distance = distance {
                environment.assignAt(distance: distance, name: name, value: value)
            } else {
                try globals.assign(name: name, value: value)
            }
            return value
        }
    }

    func executeBlock(statements: [Stmt], environment: Environment) throws {
        let previous: Environment = self.environment
        do {
            self.environment = environment
            defer { self.environment = previous }
            for statement in statements {
                try execute(stmt: statement)
            }
        }
    }

    private func execute(stmt: Stmt) throws {
        switch stmt {
        case .expression(let expr):
            try evaluate(expr: expr)
        case .if(let condition, let thenBranch, let elseBranch):
            if isTruthy(object: try evaluate(expr: condition)) {
                try execute(stmt: thenBranch)
            } else if let elseBranch = elseBranch {
                try execute(stmt: elseBranch)
            }
        case .function(let name, let params, let body):
            let function = LoxFunction(name: name, params: params, body: body, closure: environment)
            environment.define(name: String(name.lexeme), value: function)
        case .while(let condition, let body):
            while isTruthy(object: try evaluate(expr: condition)) {
                try execute(stmt: body)
            }
        case .print(let expr):
            print(stringify(object: try evaluate(expr: expr)))
        case .variable(let name, let initializer):
            var value: AnyHashable? = nil
            if let initializer = initializer {
                value = try evaluate(expr: initializer)
            }
            environment.define(name: String(name.lexeme), value: value)
        case .return(_, let value):
            guard let value = value else {
                throw Return(value: nil)
            }
            throw Return(value: try evaluate(expr: value))
        case .block(let statements):
            try executeBlock(statements: statements, environment: Environment(enclosing: environment))
        }
    }

    func interpret(statements: [Stmt]) {
        do {
            for statement in statements {
                try execute(stmt: statement)
            }
        } catch {
            let error = error as! RuntimeError
            SwiftLox.runtimeError(error: error)
        }
    }
}
