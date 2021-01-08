//
//  LoxCallable.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/08.
//

import Foundation

protocol LoxCallable {
    func call(interpreter: Interpreter, arguments: [AnyHashable?]) throws -> AnyHashable?
    func arity() -> Int
}
