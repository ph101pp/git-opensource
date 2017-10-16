#! /usr/bin/env bash

GIT_PARENT=`git log --pretty=%P -n 1 "$GIT_COMMIT"`;

if [[ $GIT_PARENT != *" "* ]]; then
  VAR=`git format-patch -1 --stdout $GIT_COMMIT`;
  # VAR=`git format-patch -1 --stdout $GIT_COMMIT|sed "s/^\+(?!\+\+\s(a|b|\/)).*$/+/"`;

  git reset $GIT_PARENT --hard;

  echo "$VAR" | git apply;
fi
