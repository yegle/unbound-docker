FROM debian:buster as build_env
ARG SOURCE_BRANCH
ENV SOURCE_BRANCH=${SOURCE_BRANCH:-1.9.6}

ENV UNBOUND_URL https://nlnetlabs.nl/downloads/unbound/unbound-${SOURCE_BRANCH}.tar.gz

RUN echo ${UNBOUND_URL}

RUN apt-get update
RUN apt-get install -y curl build-essential libexpat-dev libssl-dev

WORKDIR /tmp/build
RUN curl -O ${UNBOUND_URL}
RUN tar xvf unbound-${SOURCE_BRANCH}.tar.gz
WORKDIR /tmp/build/unbound-${SOURCE_BRANCH}
RUN ./configure --enable-tfo-server --enable-tfo-client --enable-subnet
RUN make && make install

RUN strip -s /usr/local/sbin/unbound
RUN strip -s /usr/local/sbin/unbound-host
RUN strip -s /usr/local/lib/libunbound.so.8
#RUN setcap 'cap_net_bind_service=+ep' /usr/local/sbin/unbound

# Unfortunately copying file from another container during multi-stage build
# won't preserve the extended attributes, thus I can't use the nonroot image.
FROM gcr.io/distroless/base-debian10
COPY --from=build_env /usr/local/sbin/unbound /bin/unbound
COPY --from=build_env /usr/local/sbin/unbound-host /bin/unbound-host
COPY --from=build_env /usr/local/lib/libunbound.so.8 /lib/x86_64-linux-gnu/

HEALTHCHECK CMD ["/bin/unbound-host", "-r", "g.co"]

ENTRYPOINT ["/bin/unbound", "-p"]
