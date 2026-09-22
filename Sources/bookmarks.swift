/*
    gitcheck
    bookmarks.swift

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
     Load the bookmarks from the standard file, if it exists and any are present.

     - Returns: An array of bookmarks (absolute paths to repo parent directories).
     */
    internal static func loadBookmarks() async -> [String] {

        var bookmarks: [String] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        let storeFile = home.appending(path: CONSTANTS.BOOKMARK_FILE_PATH)
        if FileManager.default.fileExists(atPath: storeFile.path) {
            do {
                let bookmarkData = try Data(contentsOf: storeFile)
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


    /**
     List pre-loaded bookmarks. This is a display-only function.

     - Parameters:
        - bookmarks: An array of bookmarked paths, as produced by `loadBookmarks()`.
     */

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
#if os(macOS)
            Stdio.report(withEmoji: "📝", "Use the '--clean' flag to remove dead bookmarks")
#else
            Stdio.report("Use the '--clean' flag to remove dead bookmarks")
#endif
        }
    }


    /**
     Write an array of bookmarks to the standard bookmark file, optionally including an
     array of additional bookmarks (provided as file URLs).

     - Parameters:
        - baseBookmarks: An array of bookmarked paths, as produced by `loadBookmarks()`.
        - newBookmarks:  An array of directory URLs to be added to the bookmark store.

     - Returns: An full array of bookmarks (absolute paths to repo parent directories).
     */
    internal static func saveBookmarks(_ baseBookmarks: [String], _ newBookmarks: [URL]) async -> [String] {

        var bookmarks = baseBookmarks

        if !newBookmarks.isEmpty {
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
        }

        if bookmarks.count >= baseBookmarks.count {
            print("***")
            let home = FileManager.default.homeDirectoryForCurrentUser
            let storeFile = home.appending(path: CONSTANTS.BOOKMARK_FILE_PATH)
            let dict: [String:[String]] = ["bookmarks": bookmarks]
            if !FileManager.default.fileExists(atPath: storeFile.path) {
                do {
                    let storeDir = home.appending(path: CONSTANTS.BOOKMARK_FILE_DIRECTORY)
                    try FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true)
                } catch {
                    Stdio.reportWarning("Could not create the bookmark store at ~/\(CONSTANTS.BOOKMARK_FILE_DIRECTORY)")
                }
            } else {
                do {
                    _ = try FileManager.default.replaceItemAt(home.appending(path: CONSTANTS.BOOKMARK_BACK_PATH), withItemAt: storeFile)
                } catch {
                    Stdio.reportError("Could not back-up the bookmark store at ~/\(CONSTANTS.BOOKMARK_FILE_DIRECTORY)")
                }
            }

            do {
                let bookmarkData = try JSONSerialization.data(withJSONObject: dict)
                try bookmarkData.write(to: storeFile)
            } catch {
                Stdio.reportError("Could not write the bookmark store")
            }
        } else {
            Stdio.reportWarning("No new bookmarks able to be added")
        }

        return bookmarks
    }


    /**
     Check each existing bookmark to confirm it still exists, remains a directory and
     contains one or more git repo directories. Bookmarks, in any, that fail these
     tests are pruned from the file.

     TODO Get the user to confirm deletion.

     - Returns `true` if no changes needed to be made, or the deletion was successful,
               otherwise `false` (error, user rejected choice)
     */
    internal static func cleanBookmarks(_ bookmarks: [String]) async -> Bool {

        // Load in the current bookmarks
        guard !bookmarks.isEmpty else { return true }

        // Check each bookmark
        var deadBookmarkIndices: [Int] = []
        var isDir: ObjCBool = false
        for (index, bookmark) in bookmarks.enumerated() {
            // Check bookmarked directory exists and is a directory
            if !FileManager.default.fileExists(atPath: bookmark, isDirectory: &isDir) || !isDir.boolValue {
                deadBookmarkIndices.append(index + 1)
                continue
            }

            // Get a bookmark directory's child files, ordered alphabetically
            guard let children = await getFiles(URL(filePath: bookmark)) else {
                deadBookmarkIndices.append(index + 1)
                continue
            }

            // Iterate over the bookmark's child files to check if any are repos,
            // ie. there's a `.git` folder in there.
            var childrenRepoCount = 0
            for file in children {
                if checkRepo(file) {
                    childrenRepoCount += 1
                }
            }

            if childrenRepoCount == 0 {
                // None of the child directories are repos
                deadBookmarkIndices.append((index + 1) * -1)
            }
        }

        // Nothing to change? Message the user and bail
        if deadBookmarkIndices.isEmpty {
            Stdio.report("No bookmarks need cleaning")
            return true
        }

        // Count the number of vanished directories and those that
        // no longer contain any repos, and report to the user
        var goners: [String] = []
        var notGitters: [String] = []
        for index in deadBookmarkIndices {
            if index > 0 {
                goners.append(bookmarks[index - 1])
            } else if index < 0 {
                notGitters.append(bookmarks[(index * -1) - 1])
            }
        }

        if goners.count == 1 {
            Stdio.report("1 bookmark references a non-existent parent directory: \(goners[0])")
        } else if goners.count > 1 {
            Stdio.report("\(goners.count) bookmarks reference non-existent parent directories: \(goners.joined(separator: ","))")
        }

        if notGitters.count == 1 {
            Stdio.report("1 bookmark references a directory containing no repos: \(notGitters[0])")
        } else if notGitters.count > 1 {
            Stdio.report("\(notGitters.count) bookmarks reference directories containing no repos: \(notGitters.joined(separator: ","))")
        }

        // Remove the dead bookmarks...
        deadBookmarkIndices = deadBookmarkIndices.map {
            if $0 < 0 {
                return ($0 * -1) - 1
            } else {
                return $0 - 1
            }
        }

        let deleteMarker = "@"
        var pruned = bookmarks
        pruned.replaceAll(at: deadBookmarkIndices, with: deleteMarker)
        let newBookmarks = makeNewList(pruned, deleteMarker)

        // ...and write out the new bookmark file
        guard let userChoice = Stdin.getCharacter("Do you wish to clean the bookmarks folder?")  else { return false }
        if userChoice != "Y" { return false }
        let saved = await saveBookmarks(newBookmarks, [])
        if saved.count != newBookmarks.count {
            Stdio.reportError("Could not clean bookmarks")
            return false
        }

        Stdio.report("Bookmarks cleaned")
        return true
    }


    internal static func deleteBookmarks(_ bookmarks: [String], _ settings: Settings) async {

        // Iterate over list of to-be-deleted items (which might be list indices or paths)
        // to assemble an array of the indexes in the `bookmarks` array that are to be deleted.
        var deletables: [Int] = []
        for deletable in settings.deletedBookmarks {
            if let first = deletable.first {
                if var numericFirst = Int(String(first)) {
                    // Index number given -- check it's in range
                    numericFirst -= 1
                    if numericFirst < 1 || numericFirst >= bookmarks.count {
                        continue
                    }

                    deletables.append(numericFirst)
                } else if String(first) == "/" {
                    // Path given -- check it's in the bookmarks list
                    for (index, bookmark) in bookmarks.enumerated() {
                        if bookmark == deletable {
                            deletables.append(index)
                            break
                        }
                    }
                }
            }
        }

        // Remove the bookmarks...
        let deleteMarker = "@"
        var pruned = bookmarks
        pruned.replaceAll(at: deletables, with: deleteMarker)
        let newBookmarks = makeNewList(pruned, deleteMarker)
        if newBookmarks.count < bookmarks.count {
            // There are bookmarks to delete, so message the user
            let deleted = bookmarks.count - newBookmarks.count
            guard let userChoice = Stdin.getCharacter("Do you wish to delete \(deleted) bookmark\(deleted == 1 ? "" : "s")?")  else { return }
            if userChoice == "Y" {
                let saved = await saveBookmarks(newBookmarks, [])
                if saved.count == newBookmarks.count {
                    Stdio.report("\(deleted) bookmark\(deleted == 1 ? "" : "s") deleted")
                } else {
                    Stdio.reportError("Could not delete \(deleted) bookmark\(deleted == 1 ? "" : "s")")
                }
            }
        }
    }


    internal static func makeNewList(_ old: [String], _ deleteable: String) -> [String] {

        return old.filter { $0 != deleteable }
    }


    /**
     Generate an array of URLs from the array of bookmark strings. These
     strings are paths to directories containing repos.

     - Parameters:
        - bookmarks: The array of bookmarks.

     - Returns: An array of URLs genrated from the bookmarked paths.
     */
    internal static func convertBookmarks(_ bookmarks: [String]) -> [URL] {

        return bookmarks.map {
            return URL(filePath: $0)
        }
    }
}
