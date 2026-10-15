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
            
            \(String(.bold))USAGE\(String(.normal))
              gitcheck [options] /path/to/parent/directory ... /path/to/parent/directory

            \(String(.bold))OPTIONS\(String(.normal))
              -f | --full               Provide status for all of the repos within parent directories.
                                        By default, \(gitcheck) only lists repos containing uncommitted
                                        or unmerged changes
              -b | --branch             List all repos’ current working branches.
            
              -a | --add                Add path arguments to the bookmarks file
              -l | --list               List bookmarks
              -d | --delete {bookmarks} Delete bookmarks by index or path
              -c | --clean              Clean out dead bookmarks
            
              -g | --gitpath {path}     Specify a specific 'git' binary (absolute path)
              
              -v | --version            \(gitcheck) version information
              -h | --help               This help screen

            Call \(gitcheck) to view the status of git repos on your computer. Pass in one or more
            parent directories to display the status of the repos they contain. 
            
            For example, if all your GitHub repos are in ~/Work/Repos/GitHub, call:
            
              gitcheck ~/Work/Repos/GitHub
            
            If you have a separate directory for GitLab repos, add it too:
            
              gitcheck ~/Work/Repos/GitHub ~/Work/Repos/GitLab
            
            If you include the --add flag, passed parent-directory paths will be bookmarked. 
            Bookmarked parent directories are examined when you call \(gitcheck) with no 
            parent-directory paths as arguments.

            """

        showHeader()
        Stdio.report(helpText)
    }


    /**
     Display the app's version number.
     */
    internal static func showHeader() {

    #if os(macOS)
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? SWIFT_BUILD_PROCESS_VERSION
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "\(SWIFT_BUILD_PROCESS_BUILD)"
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "gitcheck"
        Stdio.report("\(String(.bold))\(name) \(version) (\(build))\(String(.normal)) for macOS")
    #else
        // Linux results
        Stdio.report("\(String(.bold))gitcheck \(SWIFT_BUILD_PROCESS_VERSION) (\(SWIFT_BUILD_PROCESS_BUILD))\(String(.normal)) for Linux")
    #endif
        Stdio.report("Copyright © 2026, Tony Smith (@smittytone). Source code available under the MIT licence.")
    }

}
