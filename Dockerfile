ARG PYTHON_BASE_IMAGE=3.8-slim-buster

FROM ubuntu AS s6build
ARG S6_RELEASE
ENV S6_VERSION ${S6_RELEASE:-v2.1.0.0}
RUN apt-get update && apt-get install -y curl
RUN echo "$(dpkg --print-architecture)"
WORKDIR /tmp
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
  amd64) ARCH='amd64';; \
  arm64) ARCH='aarch64';; \
  armhf) ARCH='armhf';; \
  *) echo "unsupported architecture: $(dpkg --print-architecture)"; exit 1 ;; \
  esac \
  && set -ex \
  && echo $S6_VERSION \
  && curl -fsSLO "https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/s6-overlay-$ARCH.tar.gz"


FROM python:${PYTHON_BASE_IMAGE} AS build

ARG octoprint_ref
ENV octoprint_ref ${octoprint_ref:-master}

RUN apt-get update && apt-get install -y \
  avrdude \
  build-essential \
  cmake \
  curl \
  imagemagick \
  ffmpeg \
  fontconfig \
  g++ \
  git \
  haproxy \
  libffi-dev \
  libjpeg-dev \
  libjpeg62-turbo \
  libprotobuf-dev \
  libudev-dev \
  libusb-1.0-0-dev \
  libv4l-dev \
  openssh-client \
  v4l-utils \
  xz-utils \
  zlib1g-dev \
  x265

# unpack s6
RUN mkdir -p /data/tmp
RUN echo "============ COPY s6 ============"
COPY --from=s6build /tmp /data/tmp
RUN s6tar=$(find /data/tmp -name "s6-overlay-*.tar.gz") \
  && tar xzf $s6tar -C / 

# Install octoprint
RUN	curl -fsSLO --compressed --retry 3 --retry-delay 10 \
  https://github.com/OctoPrint/OctoPrint/archive/${octoprint_ref}.tar.gz \
	&& mkdir -p /data/opt/octoprint \
  && tar xzf ${octoprint_ref}.tar.gz --strip-components 1 -C /data/opt/octoprint --no-same-owner

WORKDIR /data/opt/octoprint
RUN pip install .
RUN mkdir -p /data/octoprint/octoprint /data/octoprint/plugins

# Install mjpg-streamer
RUN curl -fsSLO --compressed --retry 3 --retry-delay 10 \
  https://github.com/jacksonliam/mjpg-streamer/archive/master.tar.gz \
  && mkdir /data/mjpg \
  && tar xzf master.tar.gz -C /data/mjpg


WORKDIR /data/mjpg/mjpg-streamer-master/mjpg-streamer-experimental
RUN make
RUN make install

# Copy services into s6 servicedir and set default ENV vars
COPY root /data/
ENV CAMERA_DEV /dev/video10
ENV MJPG_STREAMER_INPUT -n -r 640x480
ENV PIP_USER true
ENV PYTHONUSERBASE /data/octoprint/plugins
ENV PATH "${PYTHONUSERBASE}/bin:${PATH}"
# set WORKDIR 
WORKDIR /data

# port to access haproxy frontend
EXPOSE 80

VOLUME /data

ENTRYPOINT ["/init"]
