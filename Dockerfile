FROM golang:alpine as builder

# install xcaddy
RUN \
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest && \
    rm -rf /tmp/*

# build caddy
RUN \
    xcaddy build \
        --with github.com/mholt/caddy-l4 \
        --with github.com/abiosoft/caddy-yaml \
        && \
    rm -rf /tmp/*

# make buildroot
RUN set -x && \
    mkdir -p /buildroot && \
    cd /buildroot && \
        mkdir -p usr/bin && \
        ln -s bin usr/bin && \
        # extract things
        apk fetch --no-cache busybox-static ca-certificates tzdata && \
        tar -xv -C /buildroot --exclude '.*' -f busybox-static-*.apk && \
        tar -xv -C /buildroot --exclude '.*' -f ca-certificates-*.apk && \
        tar -xv -C /buildroot -f tzdata-*.apk usr/share/zoneinfo/Asia/Chongqing && \
        rm *.apk && \
        # prepare busybox
        mv bin/busybox.static bin/busybox && \
        # link busybox
        cd bin && \
            for applet in $(./busybox --list) ; \
            do \
                ln -sf busybox "$applet" ; \
            done && \
        cd .. && \
        # cacert rehash things
        c_rehash && \
        find /etc/ssl/certs/ -name '????????.?' -exec cp '{}' etc/ssl/certs/ \; && \
        # tzinfo
        mv usr/share/zoneinfo/Asia/Chongqing etc/localtime && \
        # copy caddy
        cp /go/caddy bin && \
        rm -rf usr/share/zoneinfo


COPY entrypoint /buildroot/

FROM scratch

COPY --from=builder /buildroot /

ENTRYPOINT [ "/entrypoint" ]
