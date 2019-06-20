FROM yegle/debian-stable-with-openssl:1.1.1c as build_env

ENV UNBOUND_VERSION 1.9.2

ENV UNBOUND_URL https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz

RUN apt-get update
RUN apt-get install -y curl build-essential libexpat-dev

WORKDIR /tmp/build
RUN curl -O ${UNBOUND_URL}
RUN tar xvf unbound-${UNBOUND_VERSION}.tar.gz
WORKDIR /tmp/build/unbound-${UNBOUND_VERSION}
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
