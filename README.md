# GIT2SVN BRIDGE

[![GitHub license](https://img.shields.io/github/license/elexx/git2svn-bridge?style=flat-square)](https://github.com/elexx/git2svn-bridge/blob/master/LICENSE)
![Docker Automated build](https://img.shields.io/docker/cloud/automated/elexx/git2svn-bridge?style=flat-square)
[![Docker Build Status](https://img.shields.io/docker/cloud/build/elexx/git2svn-bridge?style=flat-square)](https://hub.docker.com/r/elexx/git2svn-bridge)
[![MicroBadger Layers](https://img.shields.io/microbadger/layers/elexx/git2svn-bridge?style=flat-square)](https://microbadger.com/images/elexx/git2svn-bridge)
![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/elexx/git2svn-bridge?style=flat-square)

During migration from SVN to GIT it might be necessary to keep an "backup" of your sources in SVN. This image helps you with syncing from GIT back to SVN.

---



## TL;DR

```bash
# once
docker docker volume create git2svnbridge_data
docker run -v git2svnbridge_data:/data elexx/git2svn-bridge:latest

# once per git/svn server
docker exec git2svn-bridge /entrypoint gitauth -s "http://gitserver/repo.git" -u "git_username" -p "git_password"
docker exec git2svn-bridge /entrypoint svnauth -s "svn://svnserver/repo" -u "svn_username" -p "svn_password"

# once per sync job - uses credentials from gitauth and svnauth
docker exec git2svn-bridge /entrypoint init -g "http://gitserver/repo.git" -s "svn://svnserver/repo"
```



## Start Container

Create a volume and run a container:

```
docker docker volume create git2svnbridge_data
docker run -v git2svnbridge_data:/data elexx/git2svn-bridge:latest
```

or bind a host directory if you prefer:
```
docker run -v ./hostdir:/data elexx/git2svn-bridge:latest
```

This will run the sync script every 15 minutes.



## Configure GIT & SVN Credentials

To be able to login to your GIT and SVN servers, the container needs the credentials. This is needed once per SVN realm and once per GIT server/repo-pair.

```bash
# GIT AUTH
docker exec git2svn-bridge /entrypoint gitauth -s "http://gitserver/repo.git" -u "git_username" -p "git_password"

# SVN AUTH
docker exec git2svn-bridge /entrypoint svnauth -s "svn://svnserver/repo" -u "svn_username" -p "svn_password"
```



## Configure a new Sync Job

Tell the sync script which git repo you want to be synced to which svn repo.  

```bash
docker exec git2svn-bridge /entrypoint init -g "http://gitserver/repo.git" -s "svn://svnserver/repo"
```



## Known limitations / TODOs

PRs to fix them are welcome!

* Does not work with certificate-based authentication.
* Only syncs the master branch.
* Split `/entrypoint` into multiple scripts which are on the $PATH to be more user-friendly on the CLI (eg "docker exec git2svn-bridge gitauth ..." without /entrypoint)
