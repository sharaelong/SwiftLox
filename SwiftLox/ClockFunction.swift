//
//  ClockFunction.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/08.
//

import Foundation

struct ClockFunction: Hashable, LoxCallable, CustomStringConvertible {
    func arity() -> Int {
        return 0
    }

    func call(interpreter: Interpreter, arguments: [AnyHashable?]) -> AnyHashable? {
        return Date().timeIntervalSince1970
    }

    var description = "<native fn>"
}
