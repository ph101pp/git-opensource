#! /usr/bin/env bash

ulimit -n 2048;
rm /tmp/log 2> /dev/null;

# CURRENT_COMMIT=`git rev-parse HEAD`;
CURRENT_BRANCH=`git branch | grep \* | cut -d ' ' -f2`;
TEMP_BRANCH="temp--git-opensource--$CURRENT_BRANCH";

git checkout --orphan "$TEMP_BRANCH";
git add -A '.'
git commit -am 'git-opensource';
SQUASH_COMMIT=`git rev-parse HEAD`;

git checkout "$CURRENT_BRANCH";
git commit --allow-empty -m "git-opensource";

# full rewrite
# git filter-branch --tree-filter '_git-opensource-full-rewrite' --commit-filter 'printf "commit,${GIT_COMMIT}," >>/tmp/log; git commit-tree "$@" | tee -a /tmp/log' -f
git filter-branch --index-filter '_git-opensource-commits' --commit-filter 'printf "commit,${GIT_COMMIT}," >>/tmp/log; git commit-tree "$@" | tee -a /tmp/log' -f

git cherry-pick --no-commit "$SQUASH_COMMIT";
rm './git-opensource';
git add -A '.'
git commit -am 'git-opensource';
git branch -df "$TEMP_BRANCH";
