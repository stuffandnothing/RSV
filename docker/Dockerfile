FROM alpine:latest
RUN apk add --no-cache runit bash fish

# runit needs these stage scripts
RUN mkdir -p /etc/runit
COPY docker/runit/1 /etc/runit/1
COPY docker/runit/2 /etc/runit/2
COPY docker/runit/3 /etc/runit/3
RUN chmod +x /etc/runit/1 /etc/runit/2 /etc/runit/3

WORKDIR /rsv
CMD ["/usr/sbin/runit"]
