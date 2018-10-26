FROM ubuntu:xenial
MAINTAINER Kyle Manna <kyle@kylemanna.com>

ARG USER_ID
ARG GROUP_ID

ENV HOME /bitcoin

# add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -g ${GROUP_ID} bitcoin \
	&& useradd -u ${USER_ID} -g bitcoin -s /bin/bash -m -d /bitcoin bitcoin

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
ENV BTCGPU_VERSION 0.15.2
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		wget \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& wget -O /tmp/bitcoin-gold-$BTCGPU_VERSION-x86_64-linux-gnu.tar.gz https://github.com/BTCGPU/BTCGPU/releases/download/v$BTCGPU_VERSION/bitcoin-gold-$BTCGPU_VERSION-x86_64-linux-gnu.tar.gz \
	&& wget -O /tmp/bitcoin-gold-$BTCGPU_VERSION.asc https://github.com/BTCGPU/BTCGPU/releases/download/v0.15.2/SHA256SUMS.asc \
	# && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 0x38EE12EB597B4FC0 \
	# && gpg --batch --verify /tmp/bitcoin-gold-$BTCGPU_VERSION.asc /tmp/bitcoin-gold-$BTCGPU_VERSION-x86_64-linux-gnu.tar.gz \
	&& tar xzf --strip-components=1 -C /usr/local/ /tmp/bitcoin-gold-$BTCGPU_VERSION-x86_64-linux-gnu.tar.gz \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& apt-get purge -y \
		ca-certificates \
		wget \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ADD ./bin /usr/local/bin

VOLUME ["/bitcoin"]

EXPOSE 8332 8333 18332 18333

WORKDIR /bitcoin

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["btc_oneshot"]
