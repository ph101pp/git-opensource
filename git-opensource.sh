#! /usr/bin/env bash
git filter-branch --tree-filter '

  c = `git format-patch -1 --stdout $GIT_COMMIT|sed "s/^\+(?!\+\+\s(a|b|\/)).*$/+/"`;
  
  git reset $GIT_COMMIT;
  
  c|git apply --cache' -f

