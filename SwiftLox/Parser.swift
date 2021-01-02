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
        return try equality()
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

        return try primary()
    }

    private func error(token: Token, message: String) -> ParseError {
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

        if (match(kinds: .leftParen)) {
            let expr = try expression()
            try consume(kind: .rightParen, message: "Expected ')' after expression.")
            return Expr.grouping(expression: expr)
        }

        throw error(token: peek(), message: "Expect Expression.")
    }

    func parse() -> Expr? {
        try? expression()
    }
}
