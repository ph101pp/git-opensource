#! /usr/bin/env bash
rm /tmp/log 2> /dev/null;
git filter-branch --index-filter '_git-opensource-tree-filter' --commit-filter 'git commit-tree "$@" | tee /tmp/log' -f