# Gitcheck 0.2.0

`gitcheck` lets you quickly view all your `git` repos that contain uncommitted or unmerged changes. It can also be used to list repos’ current branches.

## Usage

Call `gitcheck` from the command line and provide one or more parent directories. For example, if all your repos are held in a `Git` directory, call:

```shell
gitcheck $HOME/Git

Git directory /Users/smitty/GitHub repos with changes:
 age-of-bronze-info has uncommitted changes
            Decoder has unmerged changes
              depot has uncommitted changes
         devscripts has uncommitted changes
       FontWrangler has uncommitted changes
           gitcheck has uncommitted changes
           pico-sdk has uncommitted changes
           plptools has uncommitted changes
    PreviewMarkdown has uncommitted changes
        PreviewYaml has uncommitted changes
            scripts has uncommitted changes
 smittytone-dot-net has uncommitted changes
          word2text has uncommitted changes
```

To display all repos, including those without changes, add the `--full` (`-f`) flag:

```shell
gitcheck $HOME/Git --full

Git directory /Users/smitty/GitHub repos:
 age-of-bronze-info has uncommitted changes
            Decoder has unmerged changes
              depot has uncommitted changes
         devscripts has uncommitted changes
              dlist has no changes
             Docker has no changes
           dotfiles has no changes
              e6809 has no changes
       FontWrangler has uncommitted changes
           gitcheck has uncommitted changes
   HighlighterSwift has no changes
Homebrew-smittytone has no changes
     HT16K33-Python has no changes
                mnu has no changes
           pdfmaker has no changes
           pico-sdk has uncommitted changes
           plptools has uncommitted changes
        PreviewCode has no changes
        PreviewJson has no changes
    PreviewMarkdown has uncommitted changes
        PreviewYaml has uncommitted changes
            scripts has uncommitted changes
 smittytone-dot-net has uncommitted changes
          word2text has uncommitted changes
```

To list branches, use the `--branch` (`-b`) flag:

```shell
gitcheck $HOME/Git --branch

Git directory /Users/smitty/GitHub repo current branches:
 age-of-bronze-info is on main
            Decoder is on develop
              depot is on develop-spi
         devscripts is on main
              dlist is on develop
             Docker is on main
           dotfiles is on main
              e6809 is on main
       FontWrangler is on develop
           gitcheck is on main
   HighlighterSwift is on develop
Homebrew-smittytone is on main
     HT16K33-Python is on develop
                mnu is on develop-swift-6
           pdfmaker is on develop
           pico-sdk is on master
           plptools is on main
        PreviewCode is on develop
        PreviewJson is on develop
    PreviewMarkdown is on develop
        PreviewYaml is on develop-200
            scripts is on main
 smittytone-dot-net is on hugo-update
          word2text is on develop-reverse
```

If you have multiple parent directories, just add them to the call:

```shell
gitcheck $HOME/Git $HOME/GitLab $HOME/CodeBerg $HOME/repos --full
```

### Bookmarks

So you don't need to list all your `git` parent directories every time, `gitcheck` has a bookmarking system. To add a bookmark, include the `--add` (`-a`) flag:

```shell
gitcheck $HOME/Git --add
```

This stores `$HOME/Git` as a bookmark. Bookmarks are loaded every run and, if no directories are passed to `gitcheck`, are used as the utility’s input.

You can list stored bookmarks with the `--list` (`-l`) flag:

```shell
gitcheck --list

Stored bookmarks:
📁 1. /Users/smitty/Git
📁 2. /Users/smitty/WorkRepos
```

Pass the `--clean` (`-c`) flag to remove bookmarks to directories that no longer exist or are no longer parents to git repos.

Pass the `--delete` (`-d`) flag to provide a list of specific bookmarks to delete. You can pass in a bookmark’s index from `gitcheck`’s bookmark listing (as shown above) or the absolute path of the directory the bookmark represents.

### Git

By default, `gitcheck` looks for a `git` binary to call. If you have multiple `git` installations—as I do: one from Xcode Command Line Tools, the other, more up to date, installed via Homebrew—then `gitcheck` may not necessarily use the one you expect. To specify a specific `git` binary, pass in its absolute path using the `--gitpath` (`-g`) option:

```shell
gitcheck $HOME/Git --gitpath /opt/homebrew/bin/git
```

## Compilation and Installation

1. Clone this repo.
2. `cd` to the repo directory.
3. Run `swift build -c release`
4. `cp .build/release/gitcheck /usr/local/bin` (or to any other directory in your `$PATH`) 

## Versioning

The source of truth for version information is `swift.plist`. This is embedded into the macOS binary for notarization purposes and to provide `gitcheck` with version data. The Linux build instead uses the contents of the file `swift_version.swift`. This file is updated via script to follow `swift.plist`.

## Ownership

`gitcheck` code is © 2026, Tony Smith (@smittytone). It is licensed under the terms of the [MIT Licence](LICENCE.md).

## AI Usage Policy

The code in this repo was not written by AI but by the owner. However, AI has been used to assist in research, testing and code review. All code portions suggested by AI and subsequently included in this codebase have been reviewed and modified by the owner.
