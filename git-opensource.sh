#! /usr/bin/env bash

ulimit -n 2048;
rm /tmp/log 2> /dev/null;

# CURRENT_COMMIT=`git rev-parse HEAD`;
CURRENT_BRANCH=`git branch | grep \* | cut -d ' ' -f2`;
TEMP_BRANCH="temp--git-opensource--$CURRENT_BRANCH";

# squash current state of repo into single commit on new branch 
git checkout --orphan "$TEMP_BRANCH";
git add -A '.'
git commit -am 'git-opensource';
SQUASH_COMMIT=`git rev-parse HEAD`;

# back to current branch -> create empty commit to discard.
git checkout "$CURRENT_BRANCH";
git commit --allow-empty -m "git-opensource";

# full rewrite
# git filter-branch --tree-filter '_git-opensource-full-rewrite' --commit-filter 'printf "commit,${GIT_COMMIT}," >>/tmp/log; git commit-tree "$@" | tee -a /tmp/log' -f
git filter-branch --index-filter '_git-opensource-commits' --commit-filter 'printf "commit,${GIT_COMMIT}," >>/tmp/log; git commit-tree "$@" | tee -a /tmp/log' -f

# cherry pick previously saved squash commit with initial state
git cherry-pick --no-commit "$SQUASH_COMMIT";

# remove git-opensource file
rm './git-opensource';

# commit initial state ontop of new history
git add -A '.'
git commit -am 'git-opensource';

# clean up temp branch and log file
git branch -df "$TEMP_BRANCH";
rm /tmp/log 2> /dev/null;

# clean up repository
# git for-each-ref --format='delete %(refname)' refs/original | git update-ref --stdin
# git reflog expire --expire=now --all
# git gc --prune=now --aggressive