/*
    gitcheck
    main.swift

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
                        default:
                            Stdio.reportError("Unexpected value passed as an argument")
                    }
                }
                
                requiresValue = -1
                continue
            }

            if settings.deleteFlag {
                if argument.prefix(1) == "-" {
                    settings.deleteFlag = false
                } else {
                    settings.deletedBookmarks.append(argument)
                    continue
                }
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
                    settings.deleteFlag = true
                    previousArgument = argument
                case "-c", "--clean":
                    settings.cleanBookmarks = true
                    //_ = await cleanBookmarks()
                    //closeCleanly()
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

            if requiresValue > 0 && argument == collatedArguments.last {
                Stdio.reportErrorAndExit("Missing value for argument \(argument)")
            }
        }

        // Get any stored bookmarks
        var bookmarks: [String] = await loadBookmarks()
        if settings.showBookmarks {
            showBookmarks(bookmarks)
            closeCleanly()
        }

        if settings.cleanBookmarks {
            _ = await cleanBookmarks(bookmarks)
            closeCleanly()
        }
        
        if !settings.deletedBookmarks.isEmpty {
            // We have bookmarks to delete
            await deleteBookmarks(bookmarks, settings)
            closeCleanly()
        }

        if settings.addBookmarks && !settings.targetDirectories.isEmpty {
            bookmarks = await saveBookmarks(bookmarks, settings.targetDirectories)
        }

        // Check we have directories
        if settings.targetDirectories.isEmpty  {
            if bookmarks.isEmpty {
                Stdio.reportErrorAndExit("No valid target directories specified")
            }

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


    /**
     Close the utility correctly.
     */
    private static func closeCleanly() {

        Stdio.disableCtrlHandler()
        exit(EXIT_SUCCESS)
    }
}
