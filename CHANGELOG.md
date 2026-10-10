## Release Notes ##

- 0.2.0 *Unreleased*
    - Better handling of repo state and current branch determination.
    - Change display priority to favor uncommitted changes over unmerged ones.
    - Handle detached HEAD so branch names don’t appear empty.
    - Better performance through improved parallelism (`clicore` 0.8.0).
    - Improve bookmark processing.
    - Fix cases of unpushed work being missed.
    - Fix issue with presentation of repos with unknown state.
    - Fix `git` call failure handling.
    - Significant code rewrites.
    - Reset versioning.
- 0.1.0 *6 October 2026*
    - Initial Swift version, with full boookmarking functionality.
