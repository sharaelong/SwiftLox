//
//  RuntimeError.swift
//  SwiftLox
//
//  Created by 신기준 on 2021/01/03.
//

import Foundation

struct RuntimeError: Error {
    let token: Token
    let message: String
}
