//
//  ASTPrinter.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/01.
//

import Foundation

indirect enum Expr: Hashable {
    case assign(name: Token, value: Expr)
    case binary(left: Expr, operator: Token, right: Expr)
    case call(callee: Expr, paren: Token, arguments: [Expr])
    case grouping(expression: Expr)
    case literal(value: AnyHashable?)
    case logical(left: Expr, operator: Token, right: Expr)
    case unary(operator: Token, right: Expr)
    case variable(name: Token)
}
