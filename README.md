# Gitcheck 4.0.0

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

This release is 4.0.0. This is because versions 0.1.0 through 3.0.0 were shell scripts. Version 4.0.0 is the first written in Swift and includes a wider range of functionality.

## Ownership

`gitcheck` code is © 2026, Tony Smith (@smittytone). It is licensed under the terms of the [MIT Licence](LICENCE.md).

_AI was not used in the development of this software. This is a statement of plain fact, not of policy. AI tools may be used in future._
