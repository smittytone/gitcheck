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
