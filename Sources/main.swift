/*
    gitcheck
    gitcheck_main.swift

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


@main
struct Gitcheck {

    /**
     Primary CLI entry point called by OS
     */
    static func main() async {

        var settings = Settings()

#if os(macOS)
        // Use emoji markers on macOS
        Stdio.settings.useEmoji = true
#endif

        // Set up Ctrl-C trap
        Stdio.enableCtrlHandler("gitcheck interrupted -- halting")

        // Process the (separated) arguments
        let collatedArguments = Cli.unify(args: CommandLine.arguments)
        var requiresValue = -1
        var previousArgument = ""
        for argument in collatedArguments {
            // Check for post flag values
            if requiresValue > 0 {
                if argument.prefix(1) == "-" {
                    Stdio.reportErrorAndExit("Value expected for \(previousArgument)")
                } else {
                    switch requiresValue {
                        case 1:
                            settings.gitBinaryPath = argument
                        case 2:
                            settings.deletedBookmarks.append(argument)
                        default:
                            Stdio.reportError("Unexpected value passed as an argument")
                    }
                }
                
                requiresValue = -1
                continue
            }

            switch argument {
                case "-b", "--branch", "--branches":
                    settings.showBranches = true
                case "-f", "--full", "--all":
                    settings.showAllRepos = true
                case "-l", "--list":
                    settings.showBookmarks = true
                case "-a", "--add":
                    settings.addBookmarks = true
                case "-d", "--delete":
                    requiresValue = 2
                    previousArgument = argument
                case "-g", "--gitpath":
                    requiresValue = 1
                    previousArgument = argument
                case "-h", "--help":
                    showHelp()
                    closeCleanly()
                case "-v", "--version":
                    showHeader()
                    closeCleanly()
                default:
                    if argument.prefix(1) == "-" {
                        Stdio.reportErrorAndExit("Unknown argument: \(argument)")
                    }

                    // Get the directory choice
                    if checkDirectory(argument) {
                        settings.targetDirectories.append(URL(fileURLWithPath: argument))
                    } else {
                        Stdio.reportError("Directory \(argument) cannot be located")
                    }
            }
        }

        var bookmarks: [String] = await loadBookmarks()
        if settings.showBookmarks {
            showBookmarks(bookmarks)
            closeCleanly()
        }

        if settings.addBookmarks && !settings.targetDirectories.isEmpty {
            bookmarks = await saveBookmarks(bookmarks, settings.targetDirectories)
        }

        // Check we have directories
        if settings.targetDirectories.isEmpty && bookmarks.isEmpty {
            Stdio.reportErrorAndExit("No valid target directories specified")
        }

        if settings.targetDirectories.isEmpty {
            settings.targetDirectories = convertBookmarks(bookmarks)
        }

        // Place the activity signaller
        Stdio.write(message: "Checking", to: Stdio.ShellRoutes.Error)

        // Perform the status check
        let results = await getRepoStates(settings)

        // Bring the cursor back to home
        Stdio.write(message: "\r", to: Stdio.ShellRoutes.Error)

        // Display the scan results
        displayRepoStates(results, settings)

        // Close cleanly
        closeCleanly()
    }


    // MARK: Help and Info Functions

    /**
     Display help.
     */
    private static func showHelp() {

        let gitcheck = "\(String(.bold))gitcheck\(String(.normal))"
        let helpText = """
            Call \(gitcheck) to view or use a connected adaptor board's device path. If multiple adaptors are
            connected, \(gitcheck) will list them. In this case, to use one of them, call \(gitcheck) with the
            required adaptor board's index as shown in the presented list.

            \(String(.bold))USAGE\(String(.normal))
              gitcheck [--version] [--help] /path/to/git/directory

            \(String(.bold))OPTIONS\(String(.normal))
              -v | --version       \(gitcheck) version information
              -h | --help          This help screen

            """

        showHeader()
        Stdio.report(helpText)
    }


    /**
     Display the app's version number.
     */
    private static func showHeader() {

#if os(macOS)
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? SWIFT_BUILD_PROCESS_GITCHECK_VERSION
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "\(SWIFT_BUILD_PROCESS_GITCHECK_BUILD)"
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "gitcheck"
        Stdio.report("\(String(.bold))\(name) \(version) (\(build))\(String(.normal)) for macOS")
#else
        // Linux results
        Stdio.report("\(String(.bold))dlist \(SWIFT_BUILD_PROCESS_GITCHECK_VERSION) (\(SWIFT_BUILD_PROCESS_GITCHECK_BUILD))\(String(.normal)) for Linux")
#endif
        Stdio.report("Copyright © 2026, Tony Smith (@smittytone). Source code available under the MIT licence.")
    }


    /**
     Close the utility correctly.
     */
    private static func closeCleanly() {

        Stdio.disableCtrlHandler()
        exit(EXIT_SUCCESS)
    }
}
