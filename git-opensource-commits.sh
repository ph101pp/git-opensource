#! /usr/bin/env bash

###############################################################################

function getLineCounts(){
  ADD="0";
  DELETE="0";
  while read p; do
    if [[ $p =~ (([0-9]+) [^ \(]+\(\-\)) ]]; then
      DELETE=$(( $DELETE + ${BASH_REMATCH[2]} ));
    fi
    if [[ $p =~ (([0-9]+) [^ \(]+\(\+\)) ]]; then
      ADD=$(( $ADD + ${BASH_REMATCH[2]} ));
    fi
  done;
  echo "$ADD $DELETE";
}

###############################################################################

function newFilePatch(){
  PATCH=`cat /dev/stdin`;
  CHANGES=`echo "$PATCH"|grep -E '^ [0-9]+ files? changed'|getLineCounts`;
  ADDS=${CHANGES% *};

  head -n4 <<< "$PATCH";

  echo "
diff --git a/git-opensource b/git-opensource
new file mode 100644
index 00000000..b6d4bb7f
--- /dev/null
+++ b/git-opensource
@@ -0,0 +1,$ADDS @@";

  for i in $(seq $ADDS); do 
    echo "+$i: ${GIT_COMMIT:0:8}"; 
  done

  echo "--";
}

###############################################################################

function updateFilePatch(){
  PATCH=`cat /dev/stdin`;
  CHANGES=`echo "$PATCH"|grep -E '^ [0-9]+ files? changed'|getLineCounts`;
  ADDS=${CHANGES% *};
  DELETES=${CHANGES#* };
  REMOVE="";
  DELETES_HEAD="-0,0";
  ADDS_HEAD="+0,0";

  if [[ $ADDS -lt "1" ]] && [[ $DELETES -lt "1" ]]; then
    ADDS="1";
    DELETES="1";
  fi
  
  if [[ $ADDS -gt "0" ]]; then
    ADDS_HEAD="+1,$ADDS";
  fi

  if [[ $DELETES -gt "0" ]]; then
    DELETES_HEAD="-1,$DELETES";
    REMOVE=$(head -n $DELETES ./git-opensource);
  fi

  head -n4 <<< "$PATCH";

  echo "
diff --git a/git-opensource b/git-opensource
index 00000000..b6d4bb7f
--- a/git-opensource
+++ b/git-opensource
@@ $DELETES_HEAD $ADDS_HEAD @@";

  if [[ $DELETES -gt "0" ]]; then
    echo "$REMOVE" | while IFS= read -r; do
      echo "-$REPLY";
    done;
  fi

  for i in $(seq $ADDS); do 
    echo "+$i: ${GIT_COMMIT:0:8}"; 
  done

  echo "--";

}

###############################################################################
###############################################################################

GIT_OLD_PARENT=`git log --pretty=%P -n 1 "$GIT_COMMIT"`;

# if not merge commit - continue
if [[ $GIT_OLD_PARENT != *" "* ]]; then

  PATCH=`git format-patch -1 --stdout --no-renames --function-context $GIT_COMMIT`;
  PATCHED="";

  # if commit has parent -> check it out!
  if [[ $GIT_OLD_PARENT == "" ]]; then 
    git rm -r --force --quiet "./";
    PATCHED=`echo "$PATCH"|newFilePatch`;
  else  
    GIT_NEW_PARENT=`grep "commit,$GIT_OLD_PARENT," /tmp/git-opensource | cut -d, -f3`;
    git reset $GIT_NEW_PARENT --hard --quiet;
    PATCHED=`echo "$PATCH"|updateFilePatch`;
  fi 
  
  # clean working directory
  git clean --force --quiet;

  # echo "$PATCHED";
  # echo "$PATCH";

  echo "$PATCHED"|git apply --index --whitespace 'nowarn' --unidiff-zero;

# if MERGE COMMIT
else 

  # Get new parent commits
  PARENTS="";
  for COMMIT in $(echo "${GIT_OLD_PARENT}"); do
    NEW_COMMIT=$(grep "commit,$COMMIT," /tmp/git-opensource | cut -d, -f3);
    PARENTS="$PARENTS$NEW_COMMIT ";
  done

  # reset branch to base commit
  IFS=' ' read -r BASE COMMITS <<< "$PARENTS";
  git reset $BASE --hard --quiet;
  
  # merge with other commits.
  git merge --quiet --no-stat --strategy "recursive" -X "patience" --allow-unrelated-histories $COMMITS > /dev/null;

  # Remove merge markers
  sed -i '' -E "/^[<=>]{7}.*/d" ./git-opensource
  git add ./git-opensource

fi