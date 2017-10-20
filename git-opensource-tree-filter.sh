#! /usr/bin/env bash
###############################################################################

function rewritePatch(){
  FILE_PATH="dev/null";
  HUNK_START=0;
  REPLACE=0;
  D=0; #deletions count
  A=0; #additions count
  OLD_LINES=();
  REWRITTEN=0;
  while read -r LINE; do 

    ## if a new diff starts and were pre @@ hunk statements so no need to replace each line
    if [[ $LINE == "diff"* ]]; then
      REPLACE=0; # set flag to prevent line replacements

    ## if on the line defining the original file were modifying -> store it
    elif [[ $LINE =~ (^--- [ab\/]/?(.*)) ]]; then
      FILE="${BASH_REMATCH[2]}";

    ## if were on a @@ hunk statement, read hunk from file in current branch
    elif [[ $LINE =~ (^@@ -([0-9]+),([0-9]+)[^@]*@@) ]]; then
      REPLACE=1; # set flag to start line replacements
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

        # update @@ hunk definition
        echo "${BASH_REMATCH[1]}${OLD_LINES[0]}";

        # echo "$FILE: $HUNK_START, $HUNK_LENGTH";
        # printf '%s\n' "${OLD_LINES[@]}"
        # echo ${#OLD_LINES[@]};
      fi
    # if were past @@ hunk statements we have to replace diff lines
    elif [[ $REPLACE == 1 ]]; then
      REWRITTEN=1;

      if [[ $LINE =~ (^\+.*) ]]; then  
        echo "+$(($HUNK_START + $A)): $LINE";
        ((A++));
      else
        if [[ $LINE =~ (^-.*) ]]; then
          echo "-${OLD_LINES[D]}";
          ((D++));
        elif [[ (($D -le ${#OLD_LINES[@]})) ]]; then
          # if [[ ${OLD_LINES[D]} == *"No newline at end of file" ]]; then
          #   echo "\ No newline at end of file";
          # else 
          if [[ ${OLD_LINES[D]} != ""  ]]; then
            echo " ${OLD_LINES[D]}";
          fi
          ((D++));
          ((A++));
        else 
          # if [[ (($D -ge ${#OLD_LINES[@]})) && $LINE == *"No newline at end of file" ]]; then
          #   echo "\ No newline at end of file";
          if [[ $LINE != *"No newline at end of file" ]]; then
          # #   echo "/ No newline at end of file";      
          # #   echo "$LINE";

          # else 
            echo "$LINE";
          fi
          ((D++));
          ((A++));
        fi

      fi
    fi
    
    # if line was not rewritten -> rewrite.
    if [[ $REWRITTEN == "0" ]]; then
      echo "$LINE";
    else 
      REWRITTEN=0;
    fi  

  done;
}


###############################################################################

GIT_OLD_PARENT=`git log --pretty=%P -n 1 "$GIT_COMMIT"`;

# if not merge commit - continue
if [[ $GIT_OLD_PARENT != *" "* ]]; then

  # if root commit
  if [[ $GIT_OLD_PARENT == "" ]]; then  
    PATCH=`git format-patch -1 --stdout $GIT_COMMIT`;
    git rm -r --force --quiet "./";

  # if commit has parent
  else 
    GIT_NEW_PARENT=`grep "$GIT_OLD_PARENT," /tmp/log | cut -d, -f2`;
    PATCH=`git diff --patch $GIT_OLD_PARENT..$GIT_COMMIT`;
    git reset $GIT_NEW_PARENT --hard --quiet;
    git checkout $GIT_NEW_PARENT .
  fi 

  git clean --force --quiet;

  PATCHED=`echo "$PATCH"|rewritePatch`;
  
 
  # echo "$PATCHED";
#  echo "$PATCH";

 echo "$PATCHED"|git apply --index --whitespace 'nowarn';

# if merge commit - do nothing
else 

  # Get new parent commits
  PARENTS="";
  for COMMIT in $(echo "${GIT_OLD_PARENT}"); do
    NEW_COMMIT=$(grep "$COMMIT," /tmp/log | cut -d, -f2);
    PARENTS="$PARENTS$NEW_COMMIT ";
  done

  # reset branch to base commit
  IFS=' ' read -r BASE COMMITS <<< "$PARENTS";
  git reset $BASE --hard --quiet;
  git checkout $BASE .
  
  # merge with other commits.
  git merge --no-commit --strategy "recursive" -X "ours" $COMMITS;

fi