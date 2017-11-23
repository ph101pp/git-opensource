# git-opensource

Before opensourcing, it is common practice in (larger) companies to erase all git history of a projects repository. This ensures that no proprietary information or IP remains anywhere in the commits which could cause serious legal issues or security vulnerabilities. However, this practice also contradicts one of the core fundamentals of opensource culture: __Give credit where credit is due.__

`git-opensource` is a small utility trying to solve this problem. It rewrittes the current branch to a new target-branch, __erasing all content from the commit history while preserving information about contributors and their statistics__.

## Installation

TBD

## Usage
```bash
# prepare
$ cd ./path/to/your/repository
$ git checkout "branch_to_rewrite" # i.e. "master"

# run
$ git-opensource <OPTIONS> [TARGET_BRANCH]
```

The newly created `TARGET_BRANCH` can now safely be published to the community. It only contains the final version of your code, ensuring that there is ZERO proprietary information or IP hidden in its history. At the same time it still contains all information about contributions to the project.


## Options

### `-M`, `--keep-messages`
If set, original commit messages will be preserved.

### `-A`, `--author-commit`
If set, author of final squash-commit will be current git user. <br>
Note: This affects contribution statistics.

### `-m [MESSAGE]`, `--commit-message [MESSAGE]`
Defines commit message for the final squash-commit. <br>
Default: git-opensource

### `-h`, `--help`
Displays help.
