#! /usr/bin/env bash

GIT_PARENT=`git log --pretty=%P -n 1 "$GIT_COMMIT"`;


if [[ $GIT_PARENT != *" "* ]]; then

  # PATCH=`git format-patch -1 --stdout $GIT_COMMIT`;
  # PATCH=`git format-patch -1 --stdout $GIT_COMMIT|sed -e 's/^\+(?!\+\+\s(a|b|\/)).*$/\+/g'`;
  PATCH=`git format-patch -1 --stdout $GIT_COMMIT|perl -ne "s/^\+(?!\+\+\s(a|b|\/)).*$/\+/gm; print;"|perl -ne "s/^\-(?!\-\-\s(a|b|\/)).*$/\-/gm; print;"`;
  # PATCH=`git diff $GIT_PARENT...$GIT_COMMIT|perl -ne "s/^\+(?!\+\+\s(a|b|\/)).*$/\+/gm; print;"|perl -ne "s/^\-(?!\-\-\s(a|b|\/)).*$/\-/gm; print;"`;

  echo "$PATCH";
  if [[ $GIT_PARENT == "" ]]; then  
    git rm -rf "./";
  else 
    git reset $GIT_PARENT --hard;
  fi 

  # git clean -f;

  echo "$PATCH"|git apply;

  git update-index --refresh;

else 
  echo "Parent $GIT_PARENT";
fi
