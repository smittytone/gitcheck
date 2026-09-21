/*
    gitcheck
    help.swift

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
     Display help.
     */
    internal static func showHelp() {

        let gitcheck = "\(String(.bold))gitcheck\(String(.normal))"
        let helpText = """
            
            Call \(gitcheck) to view the status of git repos on your computer. Pass in one or more
            parent directories to display the status of the repos they contain. If you include 
            the --add flag, passed parent-directory paths will be bookmarked. Bookmarked directories 
            are examined when you call \(gitcheck) and pass in no parent-directory paths.

            \(String(.bold))USAGE\(String(.normal))
              gitcheck [-f] [-b] [-a] [-v] [-h] [/path/to/git/directory]

            \(String(.bold))OPTIONS\(String(.normal))
              -f | --full          Provide status for all of the repos within parent directories.
                                   By default, \(gitcheck) only lists repos containing uncommitted
                                   or unmerged changes
              -b | --branch        List all repos’ current working branches.
            
              -a | --add           Add path arguments to the bookmarks file
              -l | --list          List bookmarks
              
              -v | --version       \(gitcheck) version information
              -h | --help          This help screen

            """

        showHeader()
        Stdio.report(helpText)
    }


    /**
     Display the app's version number.
     */
    internal static func showHeader() {

    #if os(macOS)
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? SWIFT_BUILD_PROCESS_GITCHECK_VERSION
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "gitcheck"
        Stdio.report("\(String(.bold))\(name) \(version)\(String(.normal)) for macOS")
    #else
        // Linux results
        Stdio.report("\(String(.bold))dlist \(SWIFT_BUILD_PROCESS_GITCHECK_VERSION) for Linux")
    #endif
        Stdio.report("Copyright © 2026, Tony Smith (@smittytone). Source code available under the MIT licence.")
    }

}
