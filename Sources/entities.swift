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
 gitcheck-specific operational and preference values.
 */
struct Settings {

    public var targetDirectories: [URL]     = []                // A list of parent directories passed in at the CLI
    public var deletedBookmarks: [String]   = []                // A list of bookmarks to be removed UNIMPLEMENTED
    public var deleteFlag: Bool             = false
    public var showBranches: Bool           = false             // The `--branch` flag was included
    public var showAllRepos: Bool           = false             // The `--full` flag was included
    public var showBookmarks: Bool          = false             // The `--list` flag was included
    public var addBookmarks: Bool           = false             // The `--add` flag was included
    public var cleanBookmarks: Bool         = false             // The `--clean` flag was included
    public var gitBinaryPath: String?       = nil               // Optional path to a `git` installation
}


/*
 The outcome of a repo check.
 */
struct StatusResults {

    internal var widths: [Int]              = []                // Array of repo name character widths (monospaced for CLI)
    internal var repos: [RepoRecord]        = []                // Array of checked repos (see below)
    internal var noReposFound: Bool         = true              // Set if no repos were found at all
}


/*
 A repo state record.
 */
struct RepoRecord {

    var name: String                        = ""                // The repo name, i.e., the directory name
    var path: String                        = ""                // The directory's path
    var currentBranch: String               = ""                // The repo's working branch
    var state: RepoState                    = .unknown          // The repo's state (see below)
}


/*
 Possible repo states.
 */
enum RepoState: String {

    case clean                              = "no"
    case unmerged                           = "unmerged"
    case uncommitted                        = "uncommitted"
    case unknown                            = "NaN"             // Got to put something!
    case separator                          = "="


    /**
     Return a suitable colour for shell text.

     Requires `Clicore`.
     */
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
