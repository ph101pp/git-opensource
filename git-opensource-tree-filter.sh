#! /usr/bin/env bash

GIT_OLD_PARENT=`git log --pretty=%P -n 1 "$GIT_COMMIT"`;
GIT_NEW_PARENT=`cat /tmp/log 2> /dev/null`;
NEW_LINE_CONTENT=" ";

# echo "Parents: $GIT_OLD_PARENT >>>>>> $GIT_NEW_PARENT";

if [[ $GIT_NEW_PARENT != *" "* ]]; then

  if [[ $GIT_OLD_PARENT == "" ]]; then  
    PATCH=`git format-patch -1 --stdout $GIT_COMMIT`;
    git rm -r --force --quiet "./";
  else 
    # PATCH=`git format-patch -1 --stdout $GIT_NEW_PARENT..$GIT_COMMIT|perl -ne "s/^\+(?!\+\+\s(a|b|\/)).*$/\+/gm; print;"`;
    PATCH=`git diff --patch --minimal $GIT_NEW_PARENT..$GIT_COMMIT`;
    git reset $GIT_NEW_PARENT --hard --quiet;
  fi 
  # echo "$PATCH";
  git clean --force --quiet;

  PATCHED=`echo "$PATCH"|perl -ne "s/^\+(?!\+\+\s(a|b|\/)).*$/\+$NEW_LINE_CONTENT/gm; print;"`;

  echo "$PATCHED"|git apply --index --whitespace 'nowarn';

else 
  echo "Parent $GIT_NEW_PARENT";
fi
