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
     Get a git binary's path.

     - Returns: The git path or `nil` on error.
     */
    internal static func getGitPath(_ settings: Settings) async -> String? {

        if let gitPath = settings.gitBinaryPath {
            // The user passed in a git path as a CLI argument
            return gitPath
        }

        // Attempt to get the path to the local git install
        guard let gitPath = await getGit() else { return nil }
        return gitPath
    }


    /**
     Get a git installation's location.

     - Returns: The git path or `nil` on error.
     */
    internal static func getGit() async -> String? {

        let (errorCode, stdio, _) = await Processes.runProcessAsync(app: "/usr/bin/which", with: ["git"])
        return errorCode == 0 ? String(stdio.trimmingCharacters(in: .whitespacesAndNewlines)) : nil
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

        // TODO Drop regular files, so `files` contains only directories

        return files.sorted(by: { a, b in
            return a.lastPathComponent.lowercased() < b.lastPathComponent.lowercased()
        })
    }


    /**
     Run git with the supplied arguments in the specified repo directory.

     - Parameters:
        - gitPath: The path to the git binary.
        - args:    The arguments to pass to git.
        - repo:    The repo directory to run git in.

     - Returns: A tuple containing the exit code and git's output, trimmed of whitespace.
     */
    internal static func runGit(_ gitPath: String, _ args: [String], in repo: URL) async -> (Int32, String) {

        // FROM 2.1.0 -- Use git's `-C` (which works on macOS and Linux) instead of `runProcessAsync()`'s interior
        //               `task.currentDirectoryURL` as this has issues with older versions of the Linux toolchain
        let (errorCode, stdio, _) = await Processes.runProcessAsync(app: gitPath, with: ["-C", repo.path] + args, in: repo)
        return (errorCode, stdio.trimmingCharacters(in: .whitespacesAndNewlines))
    }

}
