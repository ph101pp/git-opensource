#! /usr/bin/env bash
GIT_OLD_PARENT=`git log --pretty=%P -n 1 "$GIT_COMMIT"`;
GIT_NEW_PARENT=`cat /tmp/log 2> /dev/null`;
NEW_LINE_CONTENT="test";

# echo "Parents: $GIT_OLD_PARENT >>>>>> $GIT_NEW_PARENT";

###############################################################################

function rewritePatch(){
  FILE_PATH="dev/null";
  HUNK_START=0;
  REPLACE=0;
  D=0; #deletions count
  A=0; #additions count
  OLD_LINES=();
  REWRITTEN=0;
  while read LINE; do 

    if [[ $LINE == "diff"* ]]; then
      REPLACE=0;
    elif [[ $LINE =~ (^--- [ab\/]/?(.*)) ]]; then
      FILE="${BASH_REMATCH[2]}";
    elif [[ $LINE =~ (^@@ -([0-9]+),([0-9]+)[^@]*@@) ]]; then
      REPLACE=1;
      D=1; # start at 1 for new files
      A=1; # start at 1 for new files

      # if modified file, read lines form current branch
      if [[ $FILE != "dev/null" ]]; then
        REWRITTEN=1;
        HUNK_START="${BASH_REMATCH[2]}";
        HUNK_LENGTH="${BASH_REMATCH[3]}";
        D=0; # start at 0 for modified files
        A=0; # start at 0 for modified files
        OLD_LINES=();
        while IFS= read -r; do
            OLD_LINES+=( "$REPLY" )
        done < <(tail -n+$HUNK_START $FILE | head -n$HUNK_LENGTH );

        echo "${BASH_REMATCH[1]}${OLD_LINES[0]}";

        # echo "$FILE: $HUNK_START, $HUNK_LENGTH";
        # printf '%s\n' "${OLD_LINES[@]}"
        # echo ${#OLD_LINES[@]};
      fi
    elif [[ $REPLACE == 1 ]]; then
      REWRITTEN=1;

      if [[ $LINE =~ (^\+.*) ]]; then  
        echo "+$(($HUNK_START + $A)): $GIT_COMMIT";
        ((A++));
      else
        if [[ $LINE =~ (^-.*) ]]; then
          echo "-${OLD_LINES[D]}";
        # elif [[ $LINE =~ (^\s.*) ]]; then
        #   echo " ${OLD_LINES[I]}";
          ((D++));
        else 
          echo " ${OLD_LINES[D]}"
          ((D++));
          ((A++));
        fi
      fi
    fi

    if [[ $REWRITTEN == "0" ]]; then
      echo "$LINE";
    else 
      REWRITTEN=0;
    fi  

  done;
}


###############################################################################

if [[ $GIT_OLD_PARENT != *" "* ]]; then

  if [[ $GIT_OLD_PARENT == "" ]]; then  
    PATCH=`git format-patch -1 --stdout $GIT_COMMIT`;
    git rm -r --force --quiet "./";
  else 
    PATCH=`git diff --patch $GIT_OLD_PARENT..$GIT_COMMIT`;
    git reset $GIT_NEW_PARENT --hard;
    git checkout $GIT_NEW_PARENT .
  fi 
  git clean --force --quiet;
  PATCHED=`echo "$PATCH"|rewritePatch`;
  
 echo "$PATCHED";

 echo "$PATCHED"|git apply --index --whitespace 'nowarn';

else 
  echo "Parent $GIT_NEW_PARENT";
fi
