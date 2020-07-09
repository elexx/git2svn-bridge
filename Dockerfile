FROM alpine:3.12.0

# install needed tools
RUN apk add --no-cache \
	git==2.26.2-r0 \
	git-svn==2.26.2-r0 \
	subversion==1.13.0-r2 \
	dumb-init==1.2.2-r1

# copy and chmod our entrypoint
COPY entrypoint.sh /entrypoint
RUN chmod +x /entrypoint

COPY scripts/sync.sh /etc/periodic/15min/sync
RUN chmod +x /etc/periodic/15min/sync

# mount repo and config storage
VOLUME [ "/data" ]
WORKDIR /data

# and run the repo in sync mode. see entrypoint
ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint"]
CMD ["sync"]
