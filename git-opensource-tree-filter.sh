#! /usr/bin/env bash

# VAR=`git format-patch -1 --stdout $GIT_COMMIT|sed "s/^\+(?!\+\+\s(a|b|\/)).*$/+/"`;
# git reset $GIT_COMMIT --hard;
# echo "$VAR" | git apply --cache;

echo "$PARENT";

PARENT=$GIT_COMMIT;
# git filter-branch --tree-filter '

#   c = `git format-patch -1 --stdout $GIT_COMMIT|sed "s/^\+(?!\+\+\s(a|b|\/)).*$/+/"`;
  
#   git reset $GIT_COMMIT;
  
#   c|git apply --cache' -f

