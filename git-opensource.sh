#! /usr/bin/env bash

###############################################################################

USAGE="
Usage: git-opensource <OPTIONS> [TARGET_BRANCH]
    
  TARGET_BRANCH
    Name of new branch that will contain the rewritten commits.
    Default: git-opensource

  OPTIONS
    -F | --force
        If set, TARGET_BRANCH will be overwritten if it exists.

    -M | --keep-messages
        If set, original commit messages will be preserved.

    -A | --author-commit
        If set, author of final squash-commit will be current git user.
        Note: Affects stats.

    -m | --commit-message [MESSAGE]
        Defines commit message for final squash-commit.
        Default: git-opensource

    -h | --help
        Displays help.
";

###############################################################################

function main(){

    if [[ $_GIT_OPENSOURCE_EXECUTE == "index-filter" ]]; then
        indexFilter;
        exit 0;
    elif [[ $_GIT_OPENSOURCE_EXECUTE == "commit-filter" ]]; then
        TREE=$(git commit-tree "$@");
        echo "commit,$GIT_COMMIT,$TREE" >> /tmp/git-opensource; 
        echo "$TREE";
        exit 0;
    elif [[ $_GIT_OPENSOURCE_EXECUTE == "msg-filter" ]]; then
        if [[ $KEEP_MESSAGES == 0 ]]; then 
            printf "$GIT_COMMIT"; 
        else 
            cat; 
        fi    
        exit 0;
    fi;

    ###############################################################################

    KEEP_MESSAGES=0;
    FORCE=0;
    AUTHOR_EMAIL="git-opensource@philippadrian.com";
    AUTHOR_NAME="git-opensource";
    MESSAGE="git-opensource";
    TARGET_BRANCH="git-opensource";

    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
    key="$1"
    case $key in
        -M|--keep-messages)
        KEEP_MESSAGES=1;
        shift # past argument
        ;;        
        -F|--force)
        FORCE=1;
        shift # past argument
        ;;
        -A|--author-commit)
        AUTHOR_EMAIL=`git config user.email`;
        AUTHOR_NAME=`git config user.name`;
        shift # past argument
        ;;
        -m|--commit-message)
        MESSAGE=$2;
        shift # past argument
        shift # past value
        ;;
        -h|--help)
        echo "$USAGE";
        exit 0;
        shift # past argument
        ;;    
        -*)    # unknown option
        echo "Unsupported input: $1" >&2
        echo "$USAGE" >&2
        exit 1;
        shift # past argument
        ;;
        *)    # unknown option
        if [[ $TARGET_BRANCH == "git-opensource" ]]; then
        TARGET_BRANCH=$1;
        else 
        echo "Unsupported input: $1" >&2
        echo "$USAGE" >&2
        exit 1;
        fi
        shift # past argument
        ;;
    esac
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters

    CURRENT_BRANCH=`git branch | grep \* | cut -d ' ' -f2`;
    TEMP_BRANCH="temp--$TARGET_BRANCH--git-opensource";

    ###############################################################################
    
    if [[ $CURRENT_BRANCH == $TARGET_BRANCH ]]; then 
        echo "Unsupported input: TARGET_BRANCH same as current branch: $CURRENT_BRANCH" >&2
        echo "$USAGE" >&2
        exit 1;
    fi     

    ulimit -n 2048;
    rm /tmp/git-opensource 2> /dev/null;

    # checkout target branch, create empty commit to discard and start magic
    if [[ $FORCE == 1 ]]; then 
      git branch -df $TARGET_BRANCH > /dev/null;
    fi 
    git checkout -b $TARGET_BRANCH $CURRENT_BRANCH || exit 1;
    git commit --allow-empty -m "git-opensource";
    KEEP_MESSAGES="$KEEP_MESSAGES" SELF="$0" git filter-branch --original 'refs/git-opensource' --index-filter '_GIT_OPENSOURCE_EXECUTE="index-filter" $SELF' --commit-filter '_GIT_OPENSOURCE_EXECUTE="commit-filter" $SELF "$@"' --msg-filter '_GIT_OPENSOURCE_EXECUTE="msg-filter" $SELF' -f;

    # squash current branch into single commit in temp branch
    git checkout --orphan $TEMP_BRANCH $CURRENT_BRANCH;
    git add -A '.' > /dev/null;
    git commit -am 'temp--git-opensource';
    SQUASH_COMMIT=`git rev-parse HEAD`;

    # commit squashed commit ontop of new history
    git checkout $TARGET_BRANCH;
    git cherry-pick --no-commit "$SQUASH_COMMIT";
    rm './git-opensource';
    git add -A '.'
    GIT_COMMITTER_NAME='git-opensource' GIT_COMMITTER_EMAIL='git-opensource@philippadrian.com' GIT_AUTHOR_NAME="$AUTHOR_NAME" GIT_AUTHOR_EMAIL="$AUTHOR_EMAIL" git commit -am "$MESSAGE";

    # clean up temp branch, log file and backups
    git branch -df $TEMP_BRANCH;
    rm /tmp/git-opensource 2> /dev/null;
    git for-each-ref --format='delete %(refname)' refs/git-opensource | git update-ref --stdin

    git checkout $CURRENT_BRANCH;
}

###############################################################################
###############################################################################
###############################################################################

function indexFilter(){

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
###############################################################################

main "$@";