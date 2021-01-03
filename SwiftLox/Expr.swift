//
//  ASTPrinter.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/01.
//

import Foundation

indirect enum Expr {
    case binary(left: Expr, operator: Token, right: Expr)
    case grouping(expression: Expr)
    case literal(value: AnyHashable?)
    case unary(operator: Token, right: Expr)
}
