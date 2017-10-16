#! /usr/bin/env bash

GIT_PARENT=`git log --pretty=%P -n 1 "$GIT_COMMIT"`;

if [[ $GIT_PARENT != *" "* ]]; then
  # PATCH=`git format-patch -1 --stdout $GIT_COMMIT`;
  # PATCH=`git format-patch -1 --stdout $GIT_COMMIT|sed -e 's/^\+(?!\+\+\s(a|b|\/)).*$/\+/g'`;
  PATCH=`git format-patch -1 --stdout $GIT_COMMIT|perl -ne "s/^\+(?!\+\+\s(a|b|\/)).*$/\+$GIT_COMMIT $GIT_AUTHOR_NAME/gm; print;"`;

  echo "$PATCH";

  git reset $GIT_PARENT --hard;
  git clean -f;

  echo "$PATCH"|git apply --index;
fi
