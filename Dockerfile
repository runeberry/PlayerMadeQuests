FROM woahbase/alpine-lua:x86_64
WORKDIR /pmq
ENTRYPOINT [ "/bin/bash" ]

RUN apk add --no-cache \
  make \
  curl \
  unzip \
  lua-md5 \
  build-base

RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted \
  lcov
