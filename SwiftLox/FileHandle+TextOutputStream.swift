//
//  FileHandle+TextOutputStream.swift
//  SwiftLox
//
//  Created by 신기준 on 2020/12/31.
//

import Foundation

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.write(data)
    }
}
