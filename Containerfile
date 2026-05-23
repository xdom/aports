FROM alpine:3.23

RUN mkdir /etc/apk/cache
RUN apk update && apk upgrade --available
RUN apk add --no-cache \
    abuild-rootbld \
    alpine-sdk \
    doas \
    lua-aports

RUN adduser -S -D -G abuild -u 1000 abuilder && \
    echo "permit nopass abuilder " > /etc/doas.d/10-abuilder.conf && \
    chmod 0600 /etc/doas.d/10-abuilder.conf

COPY configs/repositories /etc/apk/repositories
COPY configs/abuild.conf /etc/abuild.conf

USER abuilder
ENV USER=abuilder

RUN abuild-keygen -a -i -n
CMD ["buildrepo", "-a", "/repo", "-d", "/repo/packages", "-p", "-k", "-R", "main"]
