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
     Scan the supplied list of directories (via `settings`, each of which should have already been
     validated (that they *are* directories, and they hold git repo files), and iterate over the
     list to determine each one's `git` state.

     - Parameters:
        - settings: A gitcheck settings structure, including the targets

     - Returns: A StatusResults structure containing the collated results of the scan.
     */
    internal static func processParentDirectories(_ settings: Settings) async -> StatusResults {

        var results = StatusResults()

        // Try to get the path to the `git` binary
        guard let gitPath = await getGitPath(settings) else { return results }

        // Process the supplied list of parent directories
        for parentDirectory in settings.targetDirectories {
            let repoResult = await processParentDirectory(forDirectory: parentDirectory, gitPath, settings)
            if !repoResult.repos.isEmpty {
                // Determine the maximum name width
                let maxWidth = repoResult.repos.map(\.name.count).max() ?? 0

                // Create a result record for the parent and store it
                let parentResult = DirectoryResult(directory: parentDirectory,
                                                      width: maxWidth,
                                                      repoResult: repoResult)
                results.directories.append(parentResult)

                // We found at least one repo, so clear the flag
                results.noReposFound = false
            } else {
                if repoResult.clean {
                    // All the repos in the parent were clean
                    results.noReposFound = false
                }
            }
        }

        return results
    }


    /**
     Scan a single parent directory and determine the `git` state of its subidiary
     repo directories

     - Parameters:
        - parentDirectory: The path of repo directory to scan.
        - gitPath:         The path of the installed `git` binary.
        - settings:        A gitcheck settings structure, including the targets.

      - Returns: A RepoResult structure containing the results of the scan.
     */
    internal static func processParentDirectory(forDirectory parentDirectory: URL, _ gitPath: String, _ settings: Settings) async -> RepoResult {

        var repoResult = RepoResult()

        // Get a parent directory's files and order them alphabetically
        guard let childDirectories = await getFiles(parentDirectory) else { return repoResult }

        // Check child directories concurrently, but cap the number of simultaneous checks:
        // each `git` process opens pipes, and an unbounded group could exhaust file descriptors
        let maxConcurrentChecks = ProcessInfo.processInfo.activeProcessorCount
        var checked: [(index: Int, repo: RepoRecord?)] = []

        await withTaskGroup(of: (index: Int, repo: RepoRecord?).self) { group in
            for (index, directory) in childDirectories.enumerated() {
                // Once the cap is reached, wait for a check to finish before starting another
                if index >= maxConcurrentChecks, let result = await group.next() {
                    checked.append(result)
                    Stdio.write(message: ".", to: Stdio.ShellRoutes.Error)
                }

                group.addTask {
                    (index, await checkRepoDirectory(directory, gitPath, settings))
                }
            }

            // Collect the remaining checks
            for await result in group {
                checked.append(result)
                Stdio.write(message: ".", to: Stdio.ShellRoutes.Error)
            }
        }

        // Tasks finish in any order, so restore the alphabetical order before filtering
        for case let (_, repo?) in checked.sorted(by: { $0.index < $1.index }) {
            // Keep the record if we need to
            if settings.showAllRepos || settings.showBranches || repo.state != .clean {
                repoResult.repos.append(repo)
            }

            if repo.state == .clean {
                repoResult.clean = true
            }
        }

        return repoResult
    }


    /**
     Check a single child directory and, if it holds a `git` repo, determine its state or branch.

     - Parameters:
        - directory: The child directory to check.
        - gitPath:   The path of the installed `git` binary.
        - settings:  A gitcheck settings structure.

     - Returns: A RepoRecord, or `nil` if the directory is not a git repo.
     */
    private static func checkRepoDirectory(_ directory: URL, _ gitPath: String, _ settings: Settings) async -> RepoRecord? {

        guard checkRepo(directory) else { return nil }

        var repo = RepoRecord()
        repo.name = directory.lastPathComponent
        repo.path = directory.path

        // Get state according to our search parameters
        if settings.showBranches {
            repo.currentBranch = await getCurrentBranch(gitPath, in: directory)
        } else {
            repo.state = await getCurrentState(gitPath, in: directory)
        }

        return repo
    }

    /**
     Get a repo's current branch, or a description of where HEAD points if it is detached.

     - Parameters:
        - gitPath: The path to the git binary.
        - repo:    The repo directory.

     - Returns: The branch name, `(detached at <hash>)`, or `(unknown)` on error.
     */
    private static func getCurrentBranch(_ gitPath: String, in repo: URL) async -> String {

        let (errorCode, branch) = await runGit(gitPath, ["branch", "--show-current"], in: repo)
        guard errorCode == 0 else { return "(unknown)" }
        if !branch.isEmpty { return branch }

        // No branch name means HEAD is detached, so report the commit instead
        let (hashCode, hash) = await runGit(gitPath, ["rev-parse", "--short", "HEAD"], in: repo)
        return hashCode == 0 && !hash.isEmpty ? "(detached at \(hash))" : "(detached)"
    }


    /**
     Get a repo's current status.

     - Parameters:
        - gitPath: The path to the git binary.
        - repo:    The repo directory.

     - Returns: The state.
     */
    private static func getCurrentState(_ gitPath: String, in repo: URL) async -> RepoState {

        let statusArgs = ["status", "--porcelain=v2", "--branch", "--ahead-behind", "--untracked-files=normal", "--ignore-submodules"]
        let (errorCode, state) = await runGit(gitPath, statusArgs, in: repo)
        guard errorCode == 0 else { return .unknown }

        // Parse CLI output to get state
        var status = parseRepoStatus(state)
        if status.ahead == nil {
            status.ahead = await countUnpushedCommits(gitPath, in: repo)
        }

        return determineRepoState(status)
    }


    /**
     Examine the response from various `git status` commands to determine the repo state.

     Requires use of `Porcelain=v2` in call to `git`.

     - Parameters:
        - text: The text returned by the call to `git`.

     - Returns: A RepoState enumeration value.
     */
    private static func determineRepoState(_ status: GitStatus) -> RepoState {

        if status.hasWorkingChanges {
            return .uncommitted
        }

        if let ahead = status.ahead, ahead > 0 {
            return .unmerged
        }

        return status.behind > 0 ? .unpulled : .clean
    }


    private static func parseRepoStatus(_ text: String) -> GitStatus {

            var status = GitStatus()

            for line in text.split(separator: "\n") {
                if line.hasPrefix("# branch.ab ") {
                    // Format: `# branch.ab +<ahead> -<behind>`
                    let fields = line.split(separator: " ")
                    if fields.count >= 4 {
                        status.ahead = Int(fields[2].dropFirst())
                        status.behind = Int(fields[3].dropFirst()) ?? 0
                    }
                } else if !line.hasPrefix("# ") {
                    // Every non-header porcelain-v2 record describes a change
                    status.hasWorkingChanges = true
                }
            }

            return status
        }


    /**
     Count the commits reachable from HEAD that are not on any remote-tracking branch.
     Used when a branch has no upstream, so `git status` can't report how far ahead it is.

     FROM 4.1.0

     - Parameters:
        - gitPath: The path to the git binary.
        - repo:    The repo directory.

     - Returns: The number of unpushed commits, or 0 if the repo has no remotes or on error.
     */
    private static func countUnpushedCommits(_ gitPath: String, in repo: URL) async -> Int {

        // A repo with no remotes has nowhere to push to, so treat it as up to date
        let (remoteCode, remotes) = await runGit(gitPath, ["remote"], in: repo)
        guard remoteCode == 0, !remotes.isEmpty else { return 0 }

        let (countCode, count) = await runGit(gitPath, ["rev-list", "--count", "HEAD", "--not", "--remotes"], in: repo)
        return countCode == 0 ? Int(count) ?? 0 : 0
    }


    /**
     Output the git repo status report.

     - Parameters:
        - results:  A structure containing the analysis results.
        - setting: An app settings structure.
    */
    internal static func displayRepoStates(_ results: StatusResults, _ settings: Settings) {

        if results.directories.isEmpty {
            if results.noReposFound {
                Stdio.reportWarning("No repos found in the supplied directory or directories")
            } else {
                Stdio.report("All checked local repos are up to date")
            }
        } else {
            if settings.showBranches {
                for (index, directoryResult) in results.directories.enumerated() {
                    let prefix = index > 0 ? "\n" : ""
                    Stdio.report("\(prefix)Git directory \(String(.bold))\(directoryResult.directory.path)\(String(.normal)) repo current branches:")
                    for repo in directoryResult.repoResult.repos {
                        let spacer = String(String(repeating: " ", count: directoryResult.width - repo.name.count))
                        Stdio.report("\(spacer)\(String(.bold))\(repo.name)\(String(.normal)) is on \(String(.bold))\(repo.currentBranch)\(String(.normal))")
                    }
                }
            } else {
                for (index, directoryResult) in results.directories.enumerated() {
                    let prefix = index > 0 ? "\n" : ""
                    let parent = "\(String(.bold))\(directoryResult.directory.path)\(String(.normal))"
                    if settings.showAllRepos {
                        Stdio.report("\(prefix)Git directory \(parent) repos:")
                    } else {
                        Stdio.report("\(prefix)Git directory \(parent) repos with changes:")
                    }

                    for repo in directoryResult.repoResult.repos {
                        let spacer = String(String(repeating: " ", count: directoryResult.width - repo.name.count))
                        let changeColour = String(repo.state.colour())
                        Stdio.report("\(spacer)\(String(.bold))\(repo.name)\(String(.normal)) has \(changeColour)\(repo.state.rawValue)\(String(.normal)) changes")
                    }
                }
            }
        }
    }

}
