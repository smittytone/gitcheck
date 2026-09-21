/*
    gitcheck
    entities.swift

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


/*
 Basic structure to hold dlist-specific passable values.
 */
struct Settings {

    public var targetDirectories: [URL]     = []
    public var deletedBookmarks: [String]   = []
    public var showBranches: Bool           = false
    public var showAllRepos: Bool           = false
    public var showBookmarks: Bool          = false
    public var addBookmarks: Bool           = false
    public var gitBinaryPath: String?       = nil
}


struct StatusResults {

    internal var widths: [Int]              = []
    internal var repos: [RepoRecord]        = []
    internal var noReposFound: Bool           = true
}


struct RepoRecord {

    var name: String                        = ""
    var path: String                        = ""
    var currentBranch: String               = ""
    var state: RepoState                    = .unknown
}


enum RepoState: String {

    case clean                              = "no"
    case unmerged                           = "unmerged"
    case uncommitted                        = "uncommitted"
    case unknown                            = "NaN"
    case separator                          = "="


    func colour() -> Stdio.ShellColour {

        switch self {
            case .clean:
                return .green
            case .unmerged:
                return .yellow
            case .uncommitted:
                return .red
            default:
                return .magenta
        }
    }
}
