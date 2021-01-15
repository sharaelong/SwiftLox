//
//  Stmt.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/04.
//

import Foundation

indirect enum Stmt: Hashable {
    case block(statements: [Stmt])
    case expression(expression: Expr)
    case `if`(condition: Expr, thenBranch: Stmt, elseBranch: Stmt?)
    case function(name: Token, params: [Token], body: [Stmt])
    case `while`(condition: Expr, body: Stmt)
    case print(expression: Expr)
    case `return`(keyword: Token, value: Expr?)
    case variable(name: Token, initializer: Expr?)
}
