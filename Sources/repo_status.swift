/*
    gitcheck
    repo_status.swift

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

    /**
     Scan the supplied list of directories, each of which should have already been
     validated (that they *are* directories, and they hold git repo files), and determine
     their git state.

     - Parameters:
        - settings: A gitcheck settings structure, including the targets

     -Returns: An StatusResults structure containing the results of the scan.
     */
    internal static func getRepoStates(_ settings: Settings) async -> StatusResults {

        var results = StatusResults()
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

            // Get a parent directory's files and order the alphabetically
            if let files = await getFiles(directory) {
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
            }

            results.widths.append(max)
        }

        return results
    }

    
    /**
     Examine the response from various `git status` commands to determine
     the repo state.

     - Parameters:
        - text: The text returned by the call to `git`.

     - Returns: A RepoState enumeration value.
     */
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

     - Parameters:
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

}
