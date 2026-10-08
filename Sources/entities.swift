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
    The outcome of a complete status check.
 */
struct StatusResults {

    internal var directories: [DirectoryResult] = []             // Checked directories containing reportable repos
    internal var noReposFound: Bool         = true              // Set if no repos were found at all
}


/*
    The outcome of a parent directory check.

    FROM 4.1.0
 */
struct DirectoryResult {

    internal let directory: URL                                 // The checked parent directory
    internal let width: Int                                     // Maximum repo name width (monospaced for CLI)
    internal let repoResult: RepoResult                         // Reportable repos found in the directory
}


/*
    Repo-specific outcomes of a parent directory check.

    FROM 4.1.0
 */
struct RepoResult {

    internal var repos: [RepoRecord]        = []
    internal var clean                   = false
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
    case unknown                            = "unknown"
    // FROM 4.1.0
    case unpulled                           = "not yet pulled"



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
            case .unpulled:
                return .cyan
            default:
                return .magenta
        }
    }
}


/*
    The parts of a `git status --porcelain=v2 --branch` response that determine repo state.

    FROM 4.1.0
 */
struct GitStatus {

    var ahead: Int?                         = nil               // Commits not pushed; nil if the branch has no upstream
    var behind: Int                         = 0                 // Commits not pulled (as of the last fetch)
    var hasWorkingChanges: Bool             = false             // Staged, unstaged, untracked or conflicted files
}


/*
    Structure to hold the outcome of a failed bookmark file handling operation.
    Supports `error.localizedDescription`.

    The `code` value will be an error code (BookmarkProcessErrorKind). Its raw value can
    be used as an exit code.

    The `text` property will be an error message. It is required only by certain errors.
*/
public struct BookmarkProcessError: Error, LocalizedError {

    public var code: BookmarkProcessErrorKind   = .noError
    public var text: String?                    = nil
    public var errorDescription: String? {
        switch self.code {
            case .noError:
                return nil
            case .badCreateFile:
                return "Could not create the bookmark store at ~/\(CONSTANTS.BOOKMARK_FILE_PATH)"
            case .badWriteToFile:
                return "Could not write the bookmark store at ~/\(CONSTANTS.BOOKMARK_FILE_PATH)"
            case .badLoadFile:
                return "Could not load the bookmark store at ~/\(CONSTANTS.BOOKMARK_FILE_PATH)"
            case .badBookmarkJson:
                return "Could not process the bookmark store at ~/\(CONSTANTS.BOOKMARK_FILE_PATH)"
            }
        }
}


/*
    Bookmark file handling error codes.
    NOTE We require raw values for these, for output as stderr codes.
*/
public enum BookmarkProcessErrorKind: Int, Error {

    case noError                                = 0
    case badCreateFile                          = 1
    case badWriteToFile                         = 2
    case badLoadFile                            = 3
    case badBookmarkJson                        = 4
}
