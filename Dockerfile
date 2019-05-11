# Base build with required packages
FROM debian:stretch-slim AS setup
RUN apt-get update && apt-get --assume-yes install \
	autoconf \
	bison \
	flex \
	g++ \
	libboost-all-dev \
	libeigen3-dev \
	libtool \
	libyaml-dev \
	make \
	unzip \
	wget

# Download source code and install compiler
FROM setup AS download
ENV BIRCH_URL="https://github.com/lawmurray/Birch/archive/master.zip"
ENV BIRCH_STANDARD_URL="https://github.com/lawmurray/Birch.Standard/archive/master.zip"
RUN apt-get --assume-yes install unzip
WORKDIR /opt/
RUN wget ${BIRCH_URL} && \
		unzip master.zip && \
		mv Birch-master Birch && \
		cd Birch && \
		./autogen.sh && \
		./configure && \
		make -j$(nproc) && \
		make install && \
		cd .. && \
		rm master.zip && \
	wget ${BIRCH_STANDARD_URL} && \
		unzip master.zip && \
		mv Birch.Standard-master Birch.Standard

# Install production version (no debug)
FROM download AS nodebug
WORKDIR /opt/Birch.Standard
RUN birch build --enable-unity --disable-debug && \
	birch install --enable-unity
WORKDIR /root
CMD /bin/bash

# Install development version
FROM download AS devel
WORKDIR /opt/Birch.Standard
RUN birch build && \
	 birch install
WORKDIR /root
CMD /bin/bash

# Production image
FROM setup AS final
COPY --from=nodebug /usr/local /usr/local
WORKDIR /root
CMD /bin/bash
