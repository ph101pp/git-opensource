#! /usr/bin/env bash
git filter-branch --tree-filter 'git format-patch -1 --stdout $GIT_COMMIT|sed "s/^\+(?!\+\+\s(a|b|\/)).*$/+/"|git apply' -f