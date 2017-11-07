#! /usr/bin/env bash
###############################################################################

function rewritePatch(){
  TYPE="?";
  HUNK_START=0;
  PAST_HUNK_HEADER=0;
  REMOVED=0;
  D=0; #deletions count
  A=0; #additions count
  OLD_LINES=();
  while read -r LINE; do 

    ## if a new diff starts and were pre @@ hunk statements so no need to replace each line
    if [[ $LINE == "diff"* ]]; then
      PAST_HUNK_HEADER=0;
      TYPE="?";
      echo "$LINE";
    ## if on the line defining the original file were modifying -> store it
    elif [[ $LINE =~ (^--- [ab\/]/?(.*)) ]]; then
      FILE="${BASH_REMATCH[2]}";

      if [[ $FILE == "dev/null" ]]; then
        TYPE="ADD";
      else
        TYPE="MODIFY";
      fi
      echo "$LINE";

    elif [[ $LINE =~ (^\+\+\+ \/dev\/null) ]]; then
      TYPE="REMOVE";
      echo "$LINE";

    ## if were on a @@ hunk statement, read hunk from file in current branch
    elif [[ $LINE =~ ((^@@ -([0-9]+))(,([0-9]+))?([^@]*@@)) ]]; then
      PAST_HUNK_HEADER=1;
      # if modified file, read lines form current branch
      if [[ $TYPE == "MODIFY" ]]; then
        TYPE="MODIFY";
        HUNK_START="${BASH_REMATCH[3]}";
        HUNK_LENGTH=$( [ -z "${BASH_REMATCH[5]}" ] && echo "${BASH_REMATCH[3]}" || echo "${BASH_REMATCH[5]}");
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

      elif [[ $TYPE == "REMOVE" ]]; then
        FILE_CONTENTS=`cat $FILE`;
        LINES=`echo "$FILE_CONTENTS" | grep -c ".*"`;

        echo "${BASH_REMATCH[2]},${LINES}${BASH_REMATCH[6]}";

        echo "$FILE_CONTENTS" | while IFS= read -r; do
          echo "-$REPLY";
        done;

      elif [[ $TYPE == "ADD" ]]; then
        D=1; # start at 1 for new files
        A=1; # start at 1 for new files
        echo "$LINE";
      fi
    # if were past @@ hunk statements we have to replace diff lines
    elif [[ $PAST_HUNK_HEADER == "1" ]]; then 
      if [[ $TYPE == "MODIFY" || $TYPE == "ADD" ]]; then

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
    else
      echo "$LINE";
    fi

  done;
}

###############################################################################
###############################################################################
###############################################################################

GIT_OLD_PARENT=`git log --pretty=%P -n 1 "$GIT_COMMIT"`;

# if not merge commit - continue
if [[ $GIT_OLD_PARENT != *" "* ]]; then
  PATCH=`git format-patch -1 --stdout --function-context $GIT_COMMIT`;

  # if root commit
  if [[ $GIT_OLD_PARENT == "" ]]; then  
    git rm -r --force --quiet "./";

  # if commit has parent
  else 
    GIT_NEW_PARENT=`grep "commit,$GIT_OLD_PARENT," /tmp/log | cut -d, -f3`;
    git reset $GIT_NEW_PARENT --hard --quiet;
    git checkout $GIT_NEW_PARENT .
  fi 

  git clean --force --quiet;

  PATCHED=`echo "$PATCH"|rewritePatch`;
  
 
  echo "$PATCHED";
#  echo "$PATCH";

  echo "$PATCHED"|git apply --index --whitespace 'nowarn' --unidiff-zero;

# if MERGE COMMIT - do nothing
else 

  # Get modified files aka. merge conflict resolutions
  # echo `git show -m --diff-filter='M' --patience --format='email'  $GIT_COMMIT` > /tmp/PATCH;

  # Define custom merge tool
  # git config mergetool.git-opensource.cmd 'echo "test"; echo `cat /tmp/PATCH`';
  git config mergetool.git-opensource.cmd 'echo "merging......"';
  git config mergetool.git-opensource.trustExitCode true;

  # Get new parent commits
  PARENTS="";
  for COMMIT in $(echo "${GIT_OLD_PARENT}"); do
    NEW_COMMIT=$(grep "commit,$COMMIT," /tmp/log | cut -d, -f3);
    PARENTS="$PARENTS$NEW_COMMIT ";
  done

  # reset branch to base commit
  IFS=' ' read -r BASE COMMITS <<< "$PARENTS";
  git reset $BASE --hard --quiet;
  git checkout $BASE .
  
  # merge with other commits.
  git merge --no-commit --strategy "recursive" -X "patience" --allow-unrelated-histories $COMMITS;
  git status;

  git mergetool --tool "git-opensource" --no-prompt;


  # PATCHED=`echo "$PATCH"|rewritePatch`;
  
  # echo "$PATCHED";
  # echo "========"
  # echo "$PATCH";

  # echo "$PATCHED"|git apply --index --whitespace 'nowarn';

fi