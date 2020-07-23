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

	MESSAGE_FILE=$(mktemp)
	git log --pretty=format:'%h - (%ai) %s - %aN %n%w(64,16,16)%-b' HEAD..origin/master > "$MESSAGE_FILE"
	git merge --allow-unrelated-histories --no-ff --no-log --file "$MESSAGE_FILE" origin/master
	rm "$MESSAGE_FILE"

	git svn dcommit
done
