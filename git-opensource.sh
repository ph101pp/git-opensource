#! /usr/bin/env bash

###############################################################################

USAGE="
Usage: git-opensource <OPTIONS> [NEW_BRANCH]
    
  NEW_BRANCH
    Name of new branch that will contain the rewritten commits.
    Default: git-opensource

  OPTIONS
    -M | --keep-messages
        (flag) If set, original commit messages will be preserved.

    -A | --author-commit
        (flag) If set, author of final squash-commit will be current git user.
        Note: This throws off stats.

    -m | --commit-message [MESSAGE]
        Defines commit message for final squash-commit.
        Default: git-opensource

    -h | --help
        Displays help.
";

###############################################################################

KEEP_MESSAGES=0;
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

ulimit -n 2048;
rm /tmp/git-opensource 2> /dev/null;

# checkout target branch, create empty commit to discard and start magic
git checkout -b $TARGET_BRANCH $CURRENT_BRANCH || exit 1;
git commit --allow-empty -m "git-opensource";
KEEP_MESSAGES="$KEEP_MESSAGES" git filter-branch --original 'refs/git-opensource' --index-filter '_git-opensource-commits' --commit-filter 'printf "commit,${GIT_COMMIT}," >>/tmp/git-opensource; git commit-tree "$@" | tee -a /tmp/git-opensource' --msg-filter 'if [[ $KEEP_MESSAGES == 0 ]]; then printf "$GIT_COMMIT"; else cat; fi' -f

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
