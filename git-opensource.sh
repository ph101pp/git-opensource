#! /usr/bin/env bash
ulimit -n 2048;
rm /tmp/log 2> /dev/null;
git filter-branch --tree-filter '_git-opensource-tree-filter' --commit-filter 'printf "commit,${GIT_COMMIT}," >>/tmp/log; git commit-tree "$@" | tee -a /tmp/log' -f