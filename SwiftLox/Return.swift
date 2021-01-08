//
//  Return.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/09.
//

import Foundation

struct Return: Error {
    let value: AnyHashable?

    init(value: AnyHashable?) {
        self.value = value
    }
}
