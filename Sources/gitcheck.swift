
import Foundation
import Clicore


extension Gitcheck {

    /**
     Check that the supplied path references a directory.

     -Parameters:
        - path: Shell-generated path.

     -Returns: `true` if the path points to a directory, otherwise `false`.
     */
    internal static func checkDirectory(_ path: String) -> Bool {

        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }


    /**
     Check that the supplied URL references a repo directory:
     ie. it contains a .git sub-directory.

     -Parameters:
        - directory: A URL referencing a directory.

     -Returns: `true` if the path points to a repo directory, otherwise `false`.
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
     Scan the supplied list of directories, each of which should have already been
     validated (that they *are* directories, and they hold git repo files), and determine
     their git state.

     -Parameters:
        - settings: A gitcheck settings structure, including the targets

     -Returns: An StatusResults structure containing the results of the scan.
     */
    internal static func getRepoStates(_ settings: Settings) async -> StatusResults {

        var results = StatusResults()
        var files: [URL]
        let gitArgs: [[String]] = [
            ["status", "--ignore-submodules"],
            ["status", "--porcelain", "--ignore-submodules"]
        ]

        let gitPath: String
        if let gp = settings.gitBinaryPath {
            gitPath = gp
        } else {
            guard let gp = await getGit() else { return results }
            gitPath = gp
        }

        for directory in settings.targetDirectories {
            var max = 0

            // Add a separator record to be used in the output phase
            if results.repos.count > 0 {
                var repo = RepoRecord()
                repo.state = .separator
                results.repos.append(repo)
            }

            do {
                // Get a parent directory's files and order the alphabetically
                files = try FileManager.default.contentsOfDirectory(at: directory,
                                                                    includingPropertiesForKeys: [],
                                                                    options: .skipsHiddenFiles)
                files = files.sorted(by: { a, b in
                    return a.lastPathComponent.lowercased() < b.lastPathComponent.lowercased()
                })

                // Iterate over the parent's files
                for file in files {
                    // Add an activity marker
                    Stdio.write(message: ".", to: Stdio.ShellRoutes.Error)

                    // Test the file
                    if checkRepo(file) {
                        // The current file is a repo directory
                        results.noReposFound = false

                        var repo = RepoRecord()
                        repo.name = file.lastPathComponent
                        repo.path = file.path

                        var argIndex = 0
                        if settings.showBranches {
                            // local branch=$(git branch --show-current)
                            let (errorCode, stdio, stderr) = await Processes.runProcessAsync(app: gitPath, with: ["branch", "--show-current"], in: file)
                            if errorCode != 0 {
                                Stdio.reportError(stderr)
                            } else {
                                repo.currentBranch = String(stdio.dropLast(1))
                            }
                        } else {
                            while true {
                                let (errorCode, stdio, stderr) = await Processes.runProcessAsync(app: gitPath, with: gitArgs[argIndex], in: file)
                                if errorCode != 0 {
                                    Stdio.reportError(stderr)
                                    break
                                }

                                let state = determineRepoState(stdio)
                                if state == .unknown {
                                    argIndex += 1
                                    if argIndex == gitArgs.count {
                                        break
                                    }

                                    continue
                                } else {
                                    repo.state = state
                                    break
                                }
                            }
                        }

                        if max < repo.name.count {
                            max = repo.name.count
                        }

                        if settings.showAllRepos || settings.showBranches || repo.state != .clean {
                            results.repos.append(repo)
                        }
                    }
                }
            } catch {
                // Fall through to fail condition
            }

            results.widths.append(max)
        }

        return results
    }


    internal static func determineRepoState(_ text: String) -> RepoState {

        if text.contains("is ahead of") {
            return .unmerged
        } else if text.contains("nothing to commit, working tree clean") {
            return .clean
        } else if !text.isEmpty {
            return .uncommitted
        }

        return .unknown
    }


    /**
     Output the git repo status report.

     -Parameters:
        - results:  A structure containing the analysis results.
        - setting: An app settings structure.
    */
    internal static func displayRepoStates(_ results: StatusResults, _ settings: Settings) {

        if results.repos.isEmpty {
            if results.noReposFound {
                Stdio.reportWarning("No repos found in the supplied directory or directories")
            } else {
                Stdio.report("All checked local repos are up to date")
            }
        } else {
            var index = 0
            var width = results.widths[index]
            if settings.showBranches {
                Stdio.report("Git directory \(String(.bold))\(settings.targetDirectories[index].path)\(String(.normal)) repo current branches:")
                for repo in results.repos {
                    if repo.state == .separator {
                        index += 1
                        width = results.widths[index]
                        Stdio.report("\nGit directory \(String(.bold))\(settings.targetDirectories[index].path)\(String(.normal)) repo current branches:")
                    } else {
                        let spacer = String(String(repeating: " ", count: width - repo.name.count))
                        Stdio.report("\(spacer)\(String(.bold))\(repo.name)\(String(.normal)) is on \(String(.bold))\(repo.currentBranch)\(String(.normal))")
                    }
                }
            } else {
                var parent = "\(String(.bold))\(settings.targetDirectories[index].path)\(String(.normal))"
                if settings.showAllRepos {
                    Stdio.report("Git directory \(parent) repos:")
                } else {
                    Stdio.report("Git directory \(parent) repos with changes:")
                }

                for repo in results.repos {
                    if repo.state == .separator {
                        index += 1
                        width = results.widths[index]
                        parent = "\(String(.bold))\(settings.targetDirectories[index].path)\(String(.normal))"
                        if settings.showAllRepos {
                            Stdio.report("\nGit directory \(parent) repos:")
                        } else {
                            Stdio.report("\nGit directory \(parent) repos with changes:")
                        }
                    } else {
                        let spacer = String(String(repeating: " ", count: width - repo.name.count))
                        let changeColour = String(repo.state.colour())
                        Stdio.report("\(spacer)\(String(.bold))\(repo.name)\(String(.normal)) has \(changeColour)\(repo.state.rawValue)\(String(.normal)) changes")
                    }
                }
            }
        }
    }


    internal static func loadBookmarks() async -> [String] {

        var bookmarks: [String] = []

        let home = FileManager.default.homeDirectoryForCurrentUser
        let store = home.appending(path: ".config/gitcheck/bookmarks.json")
        if FileManager.default.fileExists(atPath: store.path) {
            do {
                let bookmarkData = try Data(contentsOf: store)
                let bookmarkStore = try JSONSerialization.jsonObject(with: bookmarkData, options: []) as! [String: [String]]
                guard let bms = bookmarkStore["bookmarks"] else { return bookmarks }
                bookmarks = bms
            } catch {
                // Load failed
                Stdio.reportError("Could not load or process the bookmark store")
            }
        }

        return bookmarks
    }


    internal static func showBookmarks(_ bookmarks: [String]) {

        if bookmarks.isEmpty {
            Stdio.report("No bookmarks stored")
        } else {
            Stdio.report("Stored bookmarks:")
            for (index, bookmark) in bookmarks.enumerated() {
#if os(macOS)
                Stdio.report(withEmoji: "📁", String(format: "%0d. %@", index + 1, bookmark))
#else
                Stdio.report(String(format: "%0d. %@", index + 1, bookmark))
#endif
            }
        }
    }


    internal static func saveBookmarks(_ baseBookmarks: [String], _ newBookmarks: [URL]) async -> [String] {

        var bookmarks: [String] = []
        for bookmark in baseBookmarks {
            bookmarks.append(bookmark)
        }

        for newBookmark in newBookmarks {
            var got = false
            for bookmark in bookmarks {
                if newBookmark.path == bookmark || String(newBookmark.path.dropLast(1)) == bookmark {
                    Stdio.reportWarning("Directory \(newBookmark.path) already bookmarked")
                    got = true
                    break
                }
            }

            if !got {
                if !checkRepo(newBookmark) {
                    Stdio.reportWarning("Directory \(newBookmark.path) contains no git repos")
                }

                bookmarks.append(newBookmark.path)
            }
        }

        if bookmarks.count > baseBookmarks.count {
            let home = FileManager.default.homeDirectoryForCurrentUser
            let store = home.appending(path: ".config/gitcheck/bookmarks.json")
            let dict: [String:[String]] = ["bookmarks": bookmarks]
            if !FileManager.default.fileExists(atPath: store.path) {
                do {
                    let storeDir = home.appending(path: ".config/gitcheck")
                    try FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true)
                } catch {
                    Stdio.reportError("Could not create the bookmark store at ~/.config/gitcheck")
                }
            } else {
                do {
                    _ = try FileManager.default.replaceItemAt(home.appending(path: ".config/gitcheck/bookmarks.bak"), withItemAt: store)
                } catch {
                    Stdio.reportError("Could not back-up the bookmark store at ~/.config/gitcheck")
                }
            }

            do {
                let bookmarkData = try JSONSerialization.data(withJSONObject: dict)
                try bookmarkData.write(to: store)
            } catch {
                // Load failed
                Stdio.reportError("Could not write the bookmark store")
            }
        } else {
            Stdio.reportWarning("No new bookmarks able to be added")
        }

        return bookmarks
    }


    internal static func convertBookmarks(_ bookmarks: [String]) -> [URL] {

        var urls: [URL] = []
        for bookmark in bookmarks {
            let url = URL(filePath: bookmark)
            urls.append(url)
        }

        return urls
    }


    internal static func getGit() async -> String? {

        let (errorCode, stdio, stderr) = await Processes.runProcessAsync(app: "/usr/bin/which", with: ["git"])
        return errorCode == 0 ? String(stdio.dropLast(1)) : stderr
    }
}
