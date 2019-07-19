FROM yegle/debian-stable-with-openssl:1.1.1c as build_env
ARG SOURCE_BRANCH
ENV SOURCE_BRANCH=${SOURCE_BRANCH:-1.9.2}

ENV UNBOUND_URL https://nlnetlabs.nl/downloads/unbound/unbound-${SOURCE_BRANCH}.tar.gz

RUN echo ${UNBOUND_URL}

RUN apt-get update
RUN apt-get install -y curl build-essential libexpat-dev

WORKDIR /tmp/build
RUN curl -O ${UNBOUND_URL}
RUN tar xvf unbound-${SOURCE_BRANCH}.tar.gz

# Temporary: fix a security issue. See
# https://github.com/NLnetLabs/unbound/issues/49
# TODO: delete once 1.9.3 is out.
RUN curl -O https://github.com/NLnetLabs/unbound/commit/c94e13220b6eea8e18c8cbbea51e4e663cb079e6.patch
# Changelog file will fail to patch.
RUN sed -i '/^diff --git a\/doc\/Changelog/,/^diff --git/d' c94e13220b6eea8e18c8cbbea51e4e663cb079e6.patch
RUN patch -p1 -d /tmp/build/unbound-${SOURCE_BRANCH} <c94e13220b6eea8e18c8cbbea51e4e663cb079e6.patch

WORKDIR /tmp/build/unbound-${SOURCE_BRANCH}
RUN ./configure --enable-tfo-server --enable-tfo-client --enable-subnet
RUN make && make install

RUN strip -s /usr/local/sbin/unbound
RUN strip -s /usr/local/sbin/unbound-host
RUN strip -s /usr/local/lib/libunbound.so.8

FROM gcr.io/distroless/base
COPY --from=build_env /usr/local/sbin/unbound /sbin/unbound
COPY --from=build_env /usr/local/sbin/unbound-host /sbin/unbound-host
COPY --from=build_env /usr/local/lib/libunbound.so.8 /lib/x86_64-linux-gnu/
COPY --from=build_env /usr/local/lib/libcrypto.so.1.1 /lib/x86_64-linux-gnu/
COPY --from=build_env /usr/local/lib/libssl.so.1.1 /lib/x86_64-linux-gnu/

HEALTHCHECK CMD ["/sbin/unbound-host", "-r", "g.co"]

ENTRYPOINT ["/sbin/unbound", "-p"]
