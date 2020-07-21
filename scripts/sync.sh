#!/usr/bin/env sh
set -euo pipefail

for d in /data/repo_* ; do
	if [[ ! -d "$d" ]] ; then
		continue
	fi

	cd "$d"

	echo "syncing $d"

	git checkout master
	git reset --hard svn/git-svn

	git fetch origin master

	MESSAGE=$(git log --pretty=format:'%h - (%ai) %s - %aN %n%w(64,16,16)%-b' HEAD..origin/master)
	git merge --allow-unrelated-histories --no-ff --no-log -m "$MESSAGE" origin/master

	git svn dcommit
done
