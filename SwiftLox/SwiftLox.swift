//
//  SwiftLox.swift
//  SwiftLox
//
//  Created by 신기준 on 2020/12/31.
//

import Foundation

class SwiftLox {
    static var hadError = false;

    static func runFile(atPath path: String) {
        guard
            let data = FileManager.default.contents(atPath: path),
            let source = String(data: data, encoding: .utf8) else {
            return
        }
        run(source)
        // if it had error
        if hadError {
            exit(65)
        }
    }

    static func runPrompt() {
        while true {
            print("> ", terminator: "")
            guard let line = readLine() else { break }
            run(line)
        }
    }

    static func run(_ source: String) {
        let scanner = Scanner(source: source)
        let tokens = scanner.scanTokens();
        let parser = Parser(tokens: tokens)
        let expression = parser.parse()

        if hadError { return }
        if let expression = expression {
            print(ASTPrinter().print(expression))
        }
    }

    static func error(atLine line: Int, withMessage message: String) {
        report(atLine: line, atPlace: "", withMessage: message)
    }

    static func error(token: Token, message: String) {
        if (token.kind == .eof) {
            report(atLine: token.line, atPlace: " at end", withMessage: message)
        } else {
            report(atLine: token.line, atPlace: "at `\(token.lexeme)`", withMessage: message)
        }
    }

    static func report(atLine line: Int, atPlace place: String,
                       withMessage message: String) {
        print("line [\(line)] Error: \(place): \(message)")
        hadError = true
    }
}
