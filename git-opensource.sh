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
git filter-branch --original 'refs/git-opensource' --index-filter '_git-opensource-commits' --commit-filter 'printf "commit,${GIT_COMMIT}," >>/tmp/log; git commit-tree "$@" | tee -a /tmp/log' --msg-filter 'printf "$GIT_COMMIT"' -f

# cherry pick previously saved squash commit with initial state
git cherry-pick --no-commit "$SQUASH_COMMIT";

# remove git-opensource file
rm './git-opensource';

# commit initial state ontop of new history
git add -A '.'
GIT_COMMITTER_NAME='git-opensource' GIT_COMMITTER_EMAIL='git-opensource@philippadrian.com' GIT_AUTHOR_NAME='git-opensource' GIT_AUTHOR_EMAIL='git-opensource@philippadrian.com' git commit -am 'git-opensource';

# clean up temp branch, log file and backups
# git branch | grep -v "^*" | xargs git branch -df 
git branch -df "$TEMP_BRANCH";
rm /tmp/log 2> /dev/null;
git for-each-ref --format='delete %(refname)' refs/git-opensource | git update-ref --stdin

# clean up repository
# git reflog expire --expire=now --all
# git gc --prune=now --aggressive