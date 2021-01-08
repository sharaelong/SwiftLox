//
//  Parser.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/02.
//

import Foundation

class Parser {
    enum ParseError: Error {
        case parseerror
    }

    private let tokens: [Token]
    private var current = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    private func isAtEnd() -> Bool {
        return peek().kind == .eof
    }

    private func previous() -> Token {
        return tokens[current - 1]
    }

    @discardableResult private func advance() -> Token {
        if (!isAtEnd()) { current += 1 }
        return previous()
    }

    private func peek() -> Token {
        return tokens[current]
    }

    private func check(kind: Token.Kind) -> Bool {
        if (isAtEnd()) { return false }
        return peek().kind == kind
    }

    private func match(kinds: Token.Kind...) -> Bool {
        for kind in kinds {
            if (check(kind: kind)) {
                advance()
                return true
            }
        }
        return false
    }

    private func expression() throws -> Expr {
        return try assignment()
    }

    private func assignment() throws -> Expr {
        let expr = try or()

        if (match(kinds: .equal)) {
            let equals = previous()
            let value = try assignment()

            if case .variable(let name) = expr {
                return Expr.assign(name: name, value: value)
            }

            throw error(token: equals, message: "Invalid assignment target")
        }

        return expr
    }

    private func or() throws -> Expr {
        var expr = try and()
        while (match(kinds: .or)) {
            let `operator` = previous()
            let right = try and()
            expr = .logical(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func and() throws -> Expr {
        var expr = try equality()
        while (match(kinds: .and)) {
            let `operator` = previous()
            let right = try equality()
            expr = .logical(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func equality() throws -> Expr {
        var expr = try comparison()

        while (match(kinds: .bangEqual, .equalEqual)) {
            let `operator` = previous()
            let right = try comparison()
            expr = Expr.binary(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func comparison() throws-> Expr {
        var expr = try term()

        while (match(kinds: .greater, .greaterEqual, .less, .lessEqual)) {
            let `operator` = previous()
            let right = try term()
            expr = Expr.binary(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func term() throws -> Expr {
        var expr = try factor()

        while (match(kinds: .minus, .plus)) {
            let `operator` = previous()
            let right = try factor()
            expr = Expr.binary(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func factor() throws -> Expr {
        var expr = try unary()

        while (match(kinds: .slash, .star)) {
            let `operator` = previous()
            let right = try unary()
            expr = Expr.binary(left: expr, operator: `operator`, right: right)
        }

        return expr
    }

    private func unary() throws -> Expr {
        if (match(kinds: .bang, .minus)) {
            let `operator` = previous()
            let right = try unary()
            return Expr.unary(operator: `operator`, right: right)
        }

        return try call()
    }

    private func call() throws -> Expr {
        var expr = try primary()
        while true {
            if match(kinds: .leftParen) {
                expr = try finishCall(callee: expr);
            } else {
                break;
            }
        }
        return expr
    }

    private func finishCall(callee: Expr) throws -> Expr {
        var arguments: [Expr] = []
        if (!check(kind: .rightParen)) {
            repeat {
                if arguments.count >= 255 {
                    error(token: peek(), message: "Can't have more than 255 arguments.")
                }
                arguments.append(try expression())
            } while match(kinds: .comma)
        }

        let paren: Token = try consume(kind: .rightParen, message: "Expect ')' after arguments.")
        return .call(callee: callee, paren: paren, arguments: arguments)
    }

    @discardableResult private func error(token: Token, message: String) -> ParseError {
        SwiftLox.error(token: token, message: message)
        return .parseerror
    }

    @discardableResult private func consume(kind: Token.Kind, message: String) throws -> Token {
        if (check(kind: kind)) { return advance() }

        throw error(token: peek(), message: message)
    }

    private func synchronize() {
        advance()

        while !isAtEnd() {
            if (previous().kind == .semicolon) { return }

            switch peek().kind {
            case .class, .fun, .var, .for, .if, .while, .return, .print:
                return
            default:
                break
            }

            advance()
        }
    }

    private func primary() throws -> Expr {
        if (match(kinds: .false)) { return Expr.literal(value: false) }
        if (match(kinds: .true)) { return Expr.literal(value: true) }
        if (match(kinds: .nil)) { return Expr.literal(value: nil) }

        if (match(kinds: .number, .string)) {
            return Expr.literal(value: previous().value)
        }

        if (match(kinds: .identifier)) {
            return Expr.variable(name: previous())
        }

        if (match(kinds: .leftParen)) {
            let expr = try expression()
            try consume(kind: .rightParen, message: "Expected ')' after expression.")
            return Expr.grouping(expression: expr)
        }

        throw error(token: peek(), message: "Expect Expression.")
    }

    private func printStatement() throws -> Stmt {
        let value = try expression()
        try consume(kind: .semicolon, message: "Expect ';' after value.")
        return Stmt.print(expression: value)
    }

    private func forStatement() throws -> Stmt {
        try consume(kind: .leftParen, message: "Expect '(' after 'for'.")

        var initializer: Stmt? = nil
        if (match(kinds: .semicolon)) {
            initializer = nil
        } else if (match(kinds: .var)) {
            initializer = try varDeclaration()
        } else {
            initializer = try expressionStatement()
        }

        var condition: Expr? = nil
        if !check(kind: .semicolon) {
            condition = try expression()
        }
        try consume(kind: .semicolon, message: "Expect ';' after loop condition.")

        var increment: Expr? = nil
        if !check(kind: .semicolon) {
            increment = try expression()
        }
        try consume(kind: .rightParen, message: "Expect ')' after for clauses.")

        var body = try statement()
        if let increment = increment {
            body = Stmt.block(statements: [body, Stmt.expression(expression: increment)])
        }
        if condition == nil { condition = Expr.literal(value: true) }
        body = Stmt.while(condition: condition!, body: body)
        if let initializer = initializer {
            body = Stmt.block(statements: [initializer, body])
        }

        return body
    }

    private func ifStatement() throws -> Stmt {
        try consume(kind: .leftParen, message: "Expect '(' after 'if'.")
        let condition = try expression();
        try consume(kind: .rightParen, message: "Expect ')' after if condition.")

        let thenBranch = try statement()
        var elseBranch: Stmt? = nil
        if (match(kinds: .else)) {
            elseBranch = try statement()
        }

        return Stmt.if(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)
    }

    private func whileStatement() throws -> Stmt {
        try consume(kind: .leftParen, message: "Expect '(' after 'while'.")
        let condition = try expression()
        try consume(kind: .rightParen, message: "Expect ')' after while condition.")
        let body = try statement()

        return Stmt.while(condition: condition, body: body)
    }

    private func returnStatement() throws -> Stmt {
        let keyword = previous()
        var value: Expr? = nil
        if !check(kind: .semicolon) {
            value = try expression()
        }

        try consume(kind: .semicolon, message: "Expect ';' after return value.")
        return .return(keyword: keyword, value: value)
    }

    private func expressionStatement() throws -> Stmt {
        let expr = try expression()
        try consume(kind: .semicolon, message: "Expect ';' after value.")
        return Stmt.expression(expression: expr)
    }

    private func block() throws -> [Stmt] {
        var statements: [Stmt] = []

        while !check(kind: .rightBrace) && !isAtEnd() {
            if let statement = declaration() {
                statements.append(statement)
            }
        }
        try consume(kind: .rightBrace, message: "Expect '}' after block.")
        return statements
    }

    private func statement() throws -> Stmt {
        if match(kinds: .print) { return try printStatement() }
        if match(kinds: .for) { return try forStatement() }
        if match(kinds: .if) { return try ifStatement() }
        if match(kinds: .while) { return try whileStatement() }
        if match(kinds: .return) { return try returnStatement() }
        if match(kinds: .leftBrace) { return .block(statements: try block()) }
        return try expressionStatement()
    }

    private func function(kind: String) throws -> Stmt {
        let name = try consume(kind: .identifier, message: "Expect \(kind) name.")
        try consume(kind: .leftParen, message: "Expect '(' after \(kind) name.")

        var parameters: [Token] = []
        if !check(kind: .rightParen) {
            repeat {
                if parameters.count >= 255 {
                    error(token: peek(), message: "Can't have more than 255 parameters.")
                }
                parameters.append(try consume(kind: .identifier, message: "Expect parameter name."))
            } while match(kinds: .comma)
        }
        try consume(kind: .rightParen, message: "Expect ')' after parameters.")

        try consume(kind: .leftBrace, message: "Expect '{' before \(kind) body.")
        let body = try block()
        return .function(name: name, params: parameters, body: body)
    }

    private func varDeclaration() throws -> Stmt {
        let name = try consume(kind: .identifier, message: "Expect variable name.")

        var initializer: Expr? = nil
        if (match(kinds: .equal)) {
            initializer = try expression()
        }

        try consume(kind: .semicolon, message: "Expect ';' after variable declaration")
        return Stmt.variable(name: name, initializer: initializer)
    }

    private func declaration() -> Stmt? {
        do {
            if match(kinds: .fun) { return try function(kind: "function") }
            if match(kinds: .var) { return try varDeclaration() }
            return try statement()
        } catch {
            synchronize()
            return nil
        }
    }

    func parse() -> [Stmt] {
        var statements: [Stmt] = []
        while (!isAtEnd()) {
            if let statement = declaration() {
                statements.append(statement)
            }
        }
        return statements
    }
}
