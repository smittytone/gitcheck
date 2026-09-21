/*
    gitcheck
    utilities.swift

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
import Clicore


extension Gitcheck {

    // MARK: Utility Functions

    /**
     Check that the supplied path references a directory.

     - Parameters:
        - path: Shell-generated path.

     - Returns: `true` if the path points to a directory, otherwise `false`.
     */
    internal static func checkDirectory(_ path: String) -> Bool {

        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }


    /**
     Check that the supplied URL references a repo directory:
     ie. it contains a .git sub-directory.

     - Parameters:
        - directory: A URL referencing a directory.

     - Returns: `true` if the path points to a repo directory, otherwise `false`.
     */
    internal static func checkRepo(_ directory: URL) -> Bool {

        do {
            let subDirectories = try FileManager.default.contentsOfDirectory(at: directory,
                                                                             includingPropertiesForKeys: [],
                                                                             options: [])
            for subDirectory in subDirectories {
                if subDirectory.isDirectory && subDirectory.lastPathComponent == ".git" {
                    return true
                }
            }
        } catch {
            // Fall through
        }

        return false
    }


    /**
     Get a git installation's location.

     - Returns: The git path or `nil` on error.
     */
    internal static func getGit() async -> String? {

        let (errorCode, stdio, stderr) = await Processes.runProcessAsync(app: "/usr/bin/which", with: ["git"])
        return errorCode == 0 ? String(stdio.dropLast(1)) : stderr
    }


    /**
     Get and sort the files within a directory (this is confirmed)

     - Parameters:
        - directory: A URL referencing the target directory.

     - Returns: An array of directory contents, or `nil`.
     */
    internal static func getFiles(_ directory: URL) async -> [URL]? {

        guard checkDirectory(directory.path) else { return nil }
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [], options: []) else {
            return nil
        }

        return files.sorted(by: { a, b in
            return a.lastPathComponent.lowercased() < b.lastPathComponent.lowercased()
        })
    }
}
