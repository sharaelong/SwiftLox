//
//  Resolver.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/11.
//

import Foundation

class Resolver {
    private let interpreter: Interpreter
    private var scopes: [[String : Bool]] = []
    private var currentFunction: FunctionType = .none

    private enum FunctionType {
        case none
        case function
    }

    init(interpreter: Interpreter) {
        self.interpreter = interpreter
    }

    private func beginScope() {
        scopes.append([:])
    }

    private func endScope() {
        _ = scopes.popLast()
    }

    private func declare(name: Token) {
        if scopes.isEmpty { return }
        if scopes.last?[String(name.lexeme)] == true {
            SwiftLox.error(token: name, message: "Already variable with this name in this scope.")
        }
        scopes[scopes.count - 1][String(name.lexeme)] = false
    }

    private func define(name: Token) {
        if scopes.isEmpty { return }
        scopes[scopes.count - 1][String(name.lexeme)] = true
    }

    private func resolve(expr: Expr) {
        switch expr {
        case .variable(let name):
            if scopes.last?[String(name.lexeme)] == false {
                SwiftLox.error(token: name, message: "Can't read local variable in its own initializer.")
            }
            resolveLocal(expr: expr, name: name)
        case .assign(let name, let value):
            resolve(expr: value)
            resolveLocal(expr: expr, name: name)
        case .binary(let left, _, let right):
            resolve(expr: left)
            resolve(expr: right)
        case .call(let callee, _, let arguments):
            resolve(expr: callee)
            for argument in arguments {
                resolve(expr: argument)
            }
        case .grouping(let expression):
            resolve(expr: expression)
        case .literal(_):
            break
        case .logical(let left, _, let right):
            resolve(expr: left)
            resolve(expr: right)
        case .unary(_, let right):
            resolve(expr: right)
        }
    }

    private func resolveFunction(name: Token, params: [Token], body: [Stmt], type: FunctionType) {
        let enclosingFunction = currentFunction
        currentFunction = type

        beginScope()
        for param in params {
            declare(name: param)
            define(name: param)
        }
        resolve(statements: body)
        endScope()
        currentFunction = enclosingFunction
    }

    private func resolve(stmt: Stmt) {
        switch stmt {
        case .block(let statements):
            beginScope()
            resolve(statements: statements)
            endScope()
        case .variable(let name, let initializer):
            declare(name: name)
            if let initializer = initializer {
                resolve(expr: initializer)
            }
            define(name: name)
        case .function(let name, let params, let body):
            declare(name: name)
            define(name: name)
            resolveFunction(name: name, params: params, body: body, type: .function)
        case .expression(let expression):
            resolve(expr: expression)
        case .if(let condition, let thenBranch, let elseBranch):
            resolve(expr: condition)
            resolve(stmt: thenBranch)
            if let elseBranch = elseBranch {
                resolve(stmt: elseBranch)
            }
        case .print(let expression):
            resolve(expr: expression)
        case .return(let keyword, let value):
            if currentFunction == .none {
                SwiftLox.error(token: keyword, message: "Can't return from top-level code.")
            }
            if let value = value {
                resolve(expr: value)
            }
        case .while(let condition, let body):
            resolve(expr: condition)
            resolve(stmt: body)
        }
    }

    func resolve(statements: [Stmt]) {
        for statement in statements {
            resolve(stmt: statement)
        }
    }

    private func resolveLocal(expr: Expr, name: Token) {
        for (depth, scope) in scopes.reversed().enumerated() {
            if scope[String(name.lexeme)] != nil {
                interpreter.resolve(expr: expr, depth: depth)
            }
        }
    }
}
