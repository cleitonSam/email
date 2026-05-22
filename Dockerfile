FROM hexpm/elixir:1.18.4-erlang-27.3.4-alpine-3.21.3 AS build

ARG WITH_EXTRA=0
ARG KEILA_CLOUD=0
ARG KEILA_CLOUD_LICENSE

ENV MIX_ENV=prod
ENV RUSTLER_PRECOMPILATION_FORCE_BUILD=false
ENV LANG=C.UTF-8

RUN apk add --no-cache \
      git \
      npm \
      build-base \
      openssl \
      cmake \
      python3 \
      curl \
      bash \
      ca-certificates

WORKDIR /app

COPY mix.exs mix.lock ./
COPY config config/
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix deps.compile

COPY assets/package.json assets/package-lock.json ./assets/
RUN npm ci --prefix ./assets --no-audit --no-fund --no-progress --loglevel=error

COPY . .
RUN mix deps.clean mime --build && \
    mix assets.deploy && \
    mix release

FROM alpine:3.21

ENV HOME=/opt/app
ENV MIX_ENV=prod
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apk add --no-cache \
      openssl \
      ncurses-libs \
      libstdc++ \
      libgcc \
      ca-certificates \
      tzdata \
      bash \
      wget

WORKDIR ${HOME}

COPY --from=build /app/_build/prod/rel/keila ${HOME}
COPY ops/inetrc ${HOME}/inetrc
COPY ops/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    adduser -s /bin/sh -u 1001 -G root -h ${HOME} -S -D default && \
    mkdir -p ${HOME}/uploads && \
    chown -R 1001:0 ${HOME}

ENV ERL_INETRC=${HOME}/inetrc

ARG PORT=4000
ENV PORT=${PORT}
EXPOSE ${PORT}/tcp

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT}/" >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD []
