#! /usr/bin/env bash

ulimit -n 2048;
rm /tmp/git-opensource 2> /dev/null;

TARGET_BRANCH=$1;
CURRENT_BRANCH=`git branch | grep \* | cut -d ' ' -f2`;
TEMP_BRANCH="temp--git-opensource--$TARGET_BRANCH";

# checkout target branch, create empty commit to discard and start magic
git checkout -b $TARGET_BRANCH $CURRENT_BRANCH
git commit --allow-empty -m "git-opensource";
git filter-branch --original 'refs/git-opensource' --index-filter '_git-opensource-commits' --commit-filter 'printf "commit,${GIT_COMMIT}," >>/tmp/git-opensource; git commit-tree "$@" | tee -a /tmp/git-opensource' --msg-filter 'printf "$GIT_COMMIT"' -f

# squash current branch into single commit in temp branch
git checkout --orphan $TEMP_BRANCH $CURRENT_BRANCH;
git add -A '.' > /dev/null;
git commit -am 'git-opensource';
SQUASH_COMMIT=`git rev-parse HEAD`;

# commit initial state ontop of new history
git checkout $TARGET_BRANCH;
git cherry-pick --no-commit "$SQUASH_COMMIT";
rm './git-opensource';
git add -A '.'
GIT_COMMITTER_NAME='git-opensource' GIT_COMMITTER_EMAIL='git-opensource@philippadrian.com' GIT_AUTHOR_NAME='git-opensource' GIT_AUTHOR_EMAIL='git-opensource@philippadrian.com' git commit -am 'git-opensource';

# clean up temp branch, log file and backups
git branch -df $TEMP_BRANCH;
rm /tmp/git-opensource 2> /dev/null;
git for-each-ref --format='delete %(refname)' refs/git-opensource | git update-ref --stdin

# clean up repository
# git reflog expire --expire=now --all
# git gc --prune=now --aggressive