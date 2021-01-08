//
//  LoxFunction.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/08.
//

import Foundation

struct LoxFunction: Hashable, CustomStringConvertible, LoxCallable {

    let name: Token
    let params: [Token]
    let body: [Stmt]
    let closure: Environment
    var description: String

    init(name: Token, params: [Token], body: [Stmt], closure: Environment) {
        self.name = name
        self.params = params
        self.body = body
        self.closure = closure
        self.description = "<fn \(name.lexeme)>"
    }

    func arity() -> Int {
        params.count
    }

    func call(interpreter: Interpreter, arguments: [AnyHashable?]) throws -> AnyHashable? {
        let environment = Environment(enclosing: closure)
        for (param, argument) in zip(params, arguments) {
            environment.define(name: String(param.lexeme), value: argument)
        }
        do {
            try interpreter.executeBlock(statements: body, environment: environment)
        } catch let error as Return {
            return error.value
        }
        return nil
    }
}
