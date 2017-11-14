#! /usr/bin/env bash
###############################################################################

function newFilePatch(){
  PATCH=`cat /dev/stdin`;
  CHANGES=`grep -E '^ [0-9]+ files? changed' <<< "$PATCH"`;
  ADDS="0";

  if [[ $CHANGES =~ (([0-9]+) [^ \(]+\(\+\)) ]]; then
    ADDS=${BASH_REMATCH[2]};
  fi

  head -n4 <<< "$PATCH";

  echo "
diff --git a/git-opensource b/git-opensource
new file mode 100644
index 00000000..b6d4bb7f
--- /dev/null
+++ b/git-opensource
@@ -0,0 +1,$ADDS @@";

  for i in $(seq $ADDS); do 
    echo "+$i: $GIT_COMMIT"; 
  done

  tail -n2 <<< "$PATCH";

}

###############################################################################
# 1 file changed, 1 insertion(+), 1 deletion(-)
#([0-9]+) [^\s]+(?:\((\+|-)\))
function updateFilePatch(){
  PATCH=`cat /dev/stdin`;
  CHANGES=`grep -E '^ [0-9]+ files? changed' <<< "$PATCH"`;
  ADDS="0";
  DELETES="0";
  REMOVE="";

  if [[ $CHANGES =~ (([0-9]+) [^ \(]+\(\-\)) ]]; then
    DELETES=${BASH_REMATCH[2]};
  fi
  if [[ $CHANGES =~ (([0-9]+) [^ \(]+\(\+\)) ]]; then
    ADDS=${BASH_REMATCH[2]};
  fi

  DELETES_HEAD="-0,0";
  ADDS_HEAD="+0,0";

  if [[ $ADDS -gt "0" ]]; then
    ADDS_HEAD="+1,$ADDS";
  fi

  if [[ $DELETES -gt "0" ]]; then
    DELETES_HEAD="-1,$DELETES";
    REMOVE=$(head -n $DELETES ./git-opensource);
  fi

  head -n4 <<< "$PATCH";

  if [[ $ADDS -lt "1" ]] && [[ $DELETES -lt "1" ]]; then
    ADDS="1";
    ADDS_HEAD="+1,$ADDS";
  fi

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
    echo "+$i: $GIT_COMMIT"; 
  done

  tail -n2 <<< "$PATCH";

}

###############################################################################
###############################################################################

GIT_OLD_PARENT=`git log --pretty=%P -n 1 "$GIT_COMMIT"`;

# if not merge commit - continue
if [[ $GIT_OLD_PARENT != *" "* ]]; then

  PATCH=`git format-patch -1 --stdout --function-context $GIT_COMMIT`;
  PATCHED="";

  # if commit has parent -> check it out!
  if [[ $GIT_OLD_PARENT == "" ]]; then 
    git rm -r --force --quiet "./";
    PATCHED=`echo "$PATCH"|newFilePatch`;
  else  
    GIT_NEW_PARENT=`grep "commit,$GIT_OLD_PARENT," /tmp/log | cut -d, -f3`;
    git reset $GIT_NEW_PARENT --hard --quiet;
    PATCHED=`echo "$PATCH"|updateFilePatch`;
  fi 
  
  # clean working directory
  git clean --force --quiet;

  echo "$PATCHED";
  # echo "$PATCH";

  echo "$PATCHED"|git apply --index --whitespace 'nowarn' --unidiff-zero;

# if MERGE COMMIT
else 

  # Get modified files aka. merge conflict resolutions
  # echo `git show -m --diff-filter='M' --patience --format='email'  $GIT_COMMIT` > /tmp/PATCH;

  # Define custom merge tool
  # git config mergetool.git-opensource.cmd 'echo "test"; echo `cat /tmp/PATCH`';
  # git config mergetool.git-opensource.cmd "echo \"$GIT_COMMIT\" > './git-opensource'";
  # git config mergetool.git-opensource.trustExitCode true;
  # git config mergetool.git-opensource.keepBackup false;

  # Get new parent commits
  PARENTS="";
  for COMMIT in $(echo "${GIT_OLD_PARENT}"); do
    NEW_COMMIT=$(grep "commit,$COMMIT," /tmp/log | cut -d, -f3);
    PARENTS="$PARENTS$NEW_COMMIT ";
  done

  # reset branch to base commit
  IFS=' ' read -r BASE COMMITS <<< "$PARENTS";
  git reset $BASE --hard --quiet;
  # git checkout $BASE .
  
  # merge with other commits.
  git merge --no-commit --quiet --strategy "recursive" -X "patience" --allow-unrelated-histories $COMMITS;
  # git status;

  sed -i '' -E "/^[<=>]{7}.*/d" ./git-opensource
  # echo "$GIT_COMMIT" > './git-opensource';
  git add .
  # git mergetool --tool "git-opensource" --no-prompt;

fi