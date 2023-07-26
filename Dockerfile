FROM debian:11-slim

WORKDIR /usr/local/src

# Dependencies for libs we build, separated by empty lines:
#	- essential tools
#	- debug tools
#	- our dependencies
#	- libks dependencies
#	- libjwt dependencies
#	- libstirshaken dependencies
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		git make cmake autoconf automake ca-certificates gcc g++ gnupg2 wget \
		lsb-release pkg-config libtool \
		\
		vim gdb valgrind linux-perf lsof net-tools iptables procps tcpdump \
		sysstat libslang2 binutils openssh-client htop iputils-ping dnsutils \
		\
		libcryptx-perl libfaketime libuuid1 libcrypt-jwt-perl libdata-uuid-perl \
		\
		uuid-dev \
		\
		libjansson-dev \
		\
		libssl-dev libcurl4-openssl-dev

# Install libks
RUN git clone --branch v1.8.2 https://github.com/signalwire/libks.git \
	&& cd libks \
	&& cmake . -DCMAKE_INSTALL_PREFIX:PATH=/usr/local \
	&& make -j $(nproc) \
	&& make install

# Install libjwt (for libstirshaken)
RUN git clone https://github.com/benmcollins/libjwt.git \
	&& cd libjwt \
	&& git checkout tags/v1.15.2 \
	&& autoreconf -i \
	&& ./configure \
	&& make all -j$(nproc) \
	&& make install

# Install libstirshaken TODO checkout a specific tag when there is one available
RUN git clone https://github.com/signalwire/libstirshaken.git \
	&& cd libstirshaken/ \
	&& ./bootstrap.sh \
	&& ./configure \
	&& make -j $(nproc) \
	&& make install

RUN ldconfig

RUN mkdir -p /home/admin/stirshaken-scenarios
WORKDIR /home/admin/stirshaken-scenarios
COPY . /home/admin/stirshaken-scenarios

ENTRYPOINT ["/home/admin/stirshaken-scenarios/go.sh"]
