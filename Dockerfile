FROM debian:stretch as build_env

ENV VERSION 1.9.1

ENV DOWNLOAD_URL https://nlnetlabs.nl/downloads/unbound/unbound-${VERSION}.tar.gz

RUN apt-get update
RUN apt-get install -y curl build-essential libssl-dev libexpat-dev

WORKDIR /tmp/build
RUN curl -O ${DOWNLOAD_URL}

RUN tar xvf unbound-${VERSION}.tar.gz

WORKDIR /tmp/build/unbound-${VERSION}
RUN ./configure --enable-tfo-server --enable-tfo-client
RUN make && make install
RUN strip -s /usr/local/sbin/unbound

FROM gcr.io/distroless/base
COPY --from=build_env /usr/local/sbin/unbound /sbin/unbound
ENTRYPOINT ["/sbin/unbound"]
