/*
    gitcheck
    extensions.swift

    Copyright © 2026 Tony Smith. All rights reserved.

    MIT License
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

import Foundation


extension URL {

    // Returns `true` if the URL (a) exists and (b) references a directory,
    // otherwise `false`
    var isDirectory: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir) && isDir.boolValue
    }
}


extension Array {

    /**
     Replace one item in an array with another.

     - Parameters:
        - at:   The index of the item to replace.
        - with: The replacement item.
     */
    public mutating func replace(at index: Int, with: Element) {

        if index < 0 || index >= self.count { return }
        _ = self.remove(at: index)
        self.insert(with, at: index)
    }


    /**
     Replace a series of items in an array with a single item.

     - Parameters:
        - at:   An array of the indices of the items to replace.
        - with: The replacement item.
     */
    public mutating func replaceAll(at indices: [Int], with: Element) {

        if indices.isEmpty { return }
        for index in indices {
            self.replace(at: index, with: with)
        }
    }
}
