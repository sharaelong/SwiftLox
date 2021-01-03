//
//  Scanner.swift
//  SwiftLox
//
//  Created by 신기준 on 2020/12/31.
//

import Foundation

class Scanner {
    private var source: String
    private var start: String.Index
    private var current: String.Index
    private var line: Int
    private var tokens: [Token]

    private let keywords: [String : Token.Kind] = [
        "and": .and,
        "class": .class,
        "else": .else,
        "false": .false,
        "for": .for,
        "fun": .fun,
        "if": .if,
        "nil": .nil,
        "or": .or,
        "print": .print,
        "return": .return,
        "super": .super,
        "this": .this,
        "true": .true,
        "var": .var,
        "while": .while
    ]

    init(source: String) {
        self.source = source
        self.start = source.startIndex
        self.current = source.startIndex
        self.line = 1
        self.tokens = []
    }

    private var isAtEnd: Bool {
        current >= source.endIndex
    }

    @discardableResult private func advance() -> Character {
        let charNow = source[current]
        current = source.index(after: current)
        return charNow
    }

    // operate like advance if it is matched, else skip it
    private func match(_ expected: Character) -> Bool {
        if isAtEnd { return false }
        if source[current] != expected { return false }

        current = source.index(after: current)
        return true
    }

    private func peek() -> Character {
        if isAtEnd { return "\0" }
        return source[current]
    }

    private func peekNext() -> Character {
        if source.index(after: current) >= source.endIndex { return "\0" }
        return source[source.index(after: current)]
    }

    private func string() {
        while peek() != "\"" && !isAtEnd {
            if (peek() == "\n") { line += 1 }
            advance()
        }

        if isAtEnd {
            SwiftLox.error(atLine: line, withMessage: "Unterminated String!")
            return
        }

        advance()
        let text = source[source.index(after: start)..<source.index(before: current)]
        addToken(kind: .string, literal: text)
    }

    private func isDigit(_ charNow: Character) -> Bool {
        return charNow >= "0" && charNow <= "9"
    }

    private func number() {
        while isDigit(peek()) { advance() }
        if peek() == "." && isDigit(peekNext()) {
            advance()
            while isDigit(peek()) { advance() }
        }

        addToken(kind: .number, literal: Double(source[start..<current]))
    }

    private func isAlpha(_ charNow: Character) -> Bool {
        (charNow >= "a" && charNow <= "z") ||
        (charNow >= "A" && charNow <= "Z") || charNow == "_"
    }

    private func isAlphaNumeric(_ charNow: Character) -> Bool {
        isAlpha(charNow) || isDigit(charNow)
    }

    private func identifier() {
        while isAlphaNumeric(peek()) { advance() }

        let text = String(source[start..<current])
        let type = keywords[text] ?? .identifier
        addToken(type)
    }

    private func addToken(_ kind: Token.Kind) {
        addToken(kind: kind, literal: nil)
    }

    private func addToken(kind: Token.Kind, literal: AnyHashable?) {
        let text = source[start..<current]
        tokens.append(Token(kind, text, literal, line))
    }

    func scanTokens() -> [Token] {
        while !isAtEnd {
            start = current
            scanToken()
        }

        tokens.append(Token(.eof, "", nil, line))
        return tokens
    }

    private func scanToken() {
        let c = advance()
        switch c {
        case "(": addToken(.leftParen)
        case ")": addToken(.rightParen)
        case "{": addToken(.leftBrace)
        case "}": addToken(.rightBrace)
        case ",": addToken(.comma)
        case ".": addToken(.dot)
        case "-": addToken(.minus)
        case "+": addToken(.plus)
        case ";": addToken(.semicolon)
        case "*": addToken(.star)
        case "!": addToken(match("=") ? .bangEqual : .bang)
        case "=": addToken(match("=") ? .equalEqual : .equal)
        case "<": addToken(match("=") ? .lessEqual : .less)
        case ">": addToken(match("=") ? .greaterEqual: .greater)
        case "/":
            if match("/") {
                while peek() != "\n" && isAtEnd { advance() }
            } else {
                addToken(.slash)
            }
        case " ", "\r", "\t": break
        case "\n": line += 1
        case "\"": string()

        default:
            if isDigit(c) {
                number()
            } else if isAlpha(c) {
                identifier()
            } else {
                SwiftLox.error(atLine: line, withMessage: "Unexpected Character!")
            }
        }
    }
}
