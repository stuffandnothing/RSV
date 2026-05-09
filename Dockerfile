# Dockerfile
FROM alpine:latest
RUN apk add --no-cache runit bash fish

WORKDIR /rsv

ENTRYPOINT ["bash"]
