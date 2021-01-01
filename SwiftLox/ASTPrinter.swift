//
//  ASTPrinter.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/01.
//

import Foundation

class ASTPrinter {
    private func parenthesize(name: String, exprs: Expr...) -> String {
//        "(" + name + " " + exprs.map(print(_:)).joined(separator: " ") + ")"
        var string = "(" + name
        for expr in exprs {
            string += " "
            string += print(expr)
        }
        string += ")"
        return string
    }

    func print(_ expression: Expr) -> String {
        switch expression {
        case .binary(let left, let `operator`, let right):
            return parenthesize(name: String(`operator`.lexeme), exprs: left, right)
        case .grouping(let expression):
            return parenthesize(name: "group", exprs: expression)
        case .literal(let value):
            guard let value = value else {
                return "nil"
            }
            return "\(value)"
        case .unary(let `operator`, let right):
            return parenthesize(name: String(`operator`.lexeme), exprs: right)
        }
    }
}
