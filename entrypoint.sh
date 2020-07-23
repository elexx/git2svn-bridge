#!/usr/bin/env sh
set -euo pipefail

PROGNAME="$0"

main()
{
	if [ "$#" == 0 ]; then
		usage; exit 1
	fi

	COMMAND="$1"; shift

	case $COMMAND in
		sync ) sync "$@"; exit 0 ;;
		svnauth ) svnauth "$@"; exit 0 ;;
		gitauth ) gitauth "$@"; exit 0 ;;
		init ) init "$@"; exit 0 ;;
		* ) usage; exit 1 ;;
	esac
}

usage()
{
	echo "usage:  ${PROGNAME}"
	echo "   sync              does not take furhter parameters, just runs cron"
	echo "   svnauth           Creates and caches the given credentials for a SVN connection"
	echo "      -s <url>       SVN repository url http://svnserver/repo/"
	echo "      -u <username>  SVN username"
	echo "      -p <password>  SVN password"
	echo "   gitauth           Creates and caches the given credentials for a GIT connection"
	echo "      -s <url>       GIT repository url http://gitserver/repo.git"
	echo "      -u <username>  GIT username"
	echo "      -p <password>  GIT password"
	echo "   init              initializes a new repository to be sync by the sync command"
	echo "      -g <url>       GIT repository url http://gitserver/repo.git"
	echo "      -s <url>       SVN repository url http://svnserver/repo/trunk include the path to the branch!"
	echo "      -c <commit>    OPTIONAL: SHA-1 of the last GIT commit that has been committet so SVN."
}

sync()
{
	echo "running sync ..."
	crond -f
}

svnauth()
{
	echo "running svnauth ..."
	SVN_REPO_URL=
	SVN_USERNAME=
	SVN_PASSWORD=

	while getopts "s:u:p:" option; do
		case "${option}" in
			s ) SVN_REPO_URL="$OPTARG" ;;
			u ) SVN_USERNAME="$OPTARG" ;;
			p ) SVN_PASSWORD="$OPTARG" ;;
			* ) usage; exit 1 ;;
		esac
	done
	shift $(($OPTIND-1))


	if [[ -z "$SVN_REPO_URL" || -z "$SVN_USERNAME" || -z "$SVN_PASSWORD" ]]; then
		usage ; exit 1
	fi

	echo "SVN: ${SVN_REPO_URL}"
	echo "Username: ${SVN_USERNAME}"
	echo "Password: hidden"

	# clean old password cache, if it exists. allows for easy re-auth in case the password changed
	AUTH_FILE=$(grep -r -l -s $(echo "$SVN_REPO_URL" | cut -d'/' -f3) "$HOME/.subversion/auth/svn.simple/" || echo "")
	if [[ -f "$AUTH_FILE" ]]; then
		echo "Old auth file found: $AUTH_FILE, will remove it"
		rm "$AUTH_FILE"
	fi

	# cache the password
	svn info --username "$SVN_USERNAME" --password "$SVN_PASSWORD" "$SVN_REPO_URL"
	AUTH_FILE=$(grep -r -l $(echo "$SVN_REPO_URL" | cut -d'/' -f3) "$HOME/.subversion/auth/svn.simple/")
	sed -i '$s/END/K 8\npassword\nV '"${#SVN_PASSWORD}\n$SVN_PASSWORD"'\nK 8\npasstype\nV 6\nsimple\nEND/g' "$AUTH_FILE"
}

gitauth()
{
	echo "running svnauth ..."
	GIT_REPO_URL=
	GIT_USERNAME=
	GIT_PASSWORD=

	while getopts "s:u:p:" option; do
		case "${option}" in
			s ) GIT_REPO_URL="$OPTARG" ;;
			u ) GIT_USERNAME="$OPTARG" ;;
			p ) GIT_PASSWORD="$OPTARG" ;;
			* ) usage; exit 1 ;;
		esac
	done
	shift $(($OPTIND-1))


	if [[ -z "$GIT_REPO_URL" || -z "$GIT_USERNAME" || -z "$GIT_PASSWORD" ]]; then
		usage ; exit 1
	fi

	echo "GIT: ${GIT_REPO_URL}"
	echo "Username: ${GIT_USERNAME}"
	echo "Password: hidden"

	git config --global credential.helper store
	cat <<-EOF | git credential approve
	url=${GIT_REPO_URL}
	username=${GIT_USERNAME}
	password=${GIT_PASSWORD}
	EOF
}

init()
{
	echo "running init ..."

	SVN_REPO_URL=
	GIT_REPO_URL=
	LAST_COMMIT=
	LOCAL_REPO_NAME=
	REVISION=1

	while getopts "s:g:c:" option; do
		case "${option}" in
			s ) SVN_REPO_URL="$OPTARG" ;;
			g ) GIT_REPO_URL="$OPTARG" ;;
			c ) LAST_COMMIT="$OPTARG" ;;
			* ) usage; exit 1 ;;
		esac
	done
	shift $(($OPTIND-1))

	if [[ -z "$SVN_REPO_URL" || -z "$GIT_REPO_URL" ]]; then
		usage ; exit 1
	fi

	D2=$(dirname "$GIT_REPO_URL")
	LOCAL_REPO_NAME=repo_$(basename "$D2")_$(basename "$GIT_REPO_URL" | cut -f 1 -d '.')

	echo "SVN: ${SVN_REPO_URL}"
	echo "GIT: ${GIT_REPO_URL}"
	echo "local folder: ${LOCAL_REPO_NAME}"
	echo "last commit: ${LAST_COMMIT}"

	# If the repo exists, get the "Last Changed Rev" otherwise bail
	svnmucc --non-interactive -m "Set SVNBridge start timestamp" propset git-svn-bridge $(date -Iseconds) "$SVN_REPO_URL"

	SVN_INFO=$(svn info "$SVN_REPO_URL" --non-interactive)
	REVISION=$(echo "$SVN_INFO" | grep "Last Changed Rev: " | cut -c19-)

	echo "latest svn revision: ${REVISION}"

	# mkdir + cd to our repo
	mkdir -p "/data/$LOCAL_REPO_NAME"
	cd "/data/$LOCAL_REPO_NAME"

	# initialize the repo
	git svn clone --prefix=svn/ -r${REVISION}:HEAD "$SVN_REPO_URL" .
	git remote add origin "$GIT_REPO_URL"
	git fetch origin master

	git config user.name "git2svn bridge"
	git config user.email "git2svn-bridge@localhost"

	if [[ ! -z "$LAST_COMMIT" ]] ; then
		git replace --graft svn/git-svn "$LAST_COMMIT"
	fi
}


# and call main
main "$@"; exit 0
################################ END OF SCRIPT ################################
