ARG PYTHON_VERSION=3-alpine

FROM python:${PYTHON_VERSION} as builder

ARG FFMPEG_URL=https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-amd64-static.tar.xz

RUN \
  apk add --no-cache gcc libffi-dev musl-dev openssl-dev python2-dev py2-pip

WORKDIR /wheels
COPY ./requirements.txt /wheels/requirements.txt

RUN \
  pip install -U pip && \
  pip wheel -r ./requirements.txt

RUN \
  mkdir /ffmpeg && \
  wget ${FFMPEG_URL} -O /ffmpeg/ffmpeg.tar.xz && \
  tar xJvf /ffmpeg/ffmpeg.tar.xz -C /ffmpeg/ --strip-components 1 && \
  rm /ffmpeg/ffmpeg.tar.xz

FROM python:${PYTHON_VERSION}

MAINTAINER James Eckersall <james.eckersall@gmail.com>

ENV PYTHONUNBUFFERED=1

COPY --from=builder /wheels /wheels
COPY --from=builder /ffmpeg/model /usr/local/share/model
COPY --from=builder /ffmpeg/ffmpeg /usr/local/bin/ffmpeg
COPY --from=builder /ffmpeg/ffprobe /usr/local/bin/ffprobe
COPY --from=builder /ffmpeg/qt-faststart /usr/local/bin/qt-faststart

RUN \
  apk add --no-cache git xz && \
  pip install -U pip && \
  pip install --no-cache-dir -r /wheels/requirements.txt -f /wheels && \
  rm -rf /wheels

RUN \
  git clone https://github.com/mdhiggins/sickbeard_mp4_automator /sba
