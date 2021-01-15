//
//  Environment.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/04.
//

import Foundation

class Environment {
    let enclosing: Environment?

    init() {
        enclosing = nil
    }

    init(enclosing: Environment?) {
        self.enclosing = enclosing
    }

    private var values: [String: AnyHashable?] = [:]

    func define(name: String, value: AnyHashable?) {
        values[name] = value
    }

    func ancestor(distance: Int) -> Environment {
        var environment = self
        for _ in 0..<distance {
            environment = environment.enclosing!
        }
        return environment
    }

    func getAt(distance: Int, name: String) -> AnyHashable? {
        return ancestor(distance: distance).values[name]!
    }

    func get(name: Token) throws -> AnyHashable? {
        if let value = values[String(name.lexeme)] {
            return value
        }

        if let enclosing = enclosing {
            return try enclosing.get(name: name)
        }

        throw RuntimeError.init(token: name, message: "Undefined Variable '\(name.lexeme)'.")
    }

    func assignAt(distance: Int, name: Token, value: AnyHashable?) {
        ancestor(distance: distance).values[String(name.lexeme)] = value
    }

    func assign(name: Token, value: AnyHashable?) throws {
        if values[String(name.lexeme)] != nil {
            values[String(name.lexeme)] = value
            return
        }

        if let enclosing = enclosing {
            try enclosing.assign(name: name, value: value)
            return
        }

        throw RuntimeError.init(token: name, message: "Undefined Variable '\(name.lexeme)'.")
    }
}

extension Environment: Hashable {
    static func == (lhs: Environment, rhs: Environment) -> Bool {
        lhs.enclosing == rhs.enclosing && lhs.values == rhs.values
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(enclosing)
        hasher.combine(values)
    }
}
