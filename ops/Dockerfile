FROM hexpm/elixir:1.18.4-erlang-27.3.4-alpine-3.21.3 AS build

ARG WITH_EXTRA=0
ARG KEILA_CLOUD=0
ARG KEILA_CLOUD_LICENSE

ENV MIX_ENV=prod

RUN apk add --no-cache git npm build-base openssl cmake

WORKDIR /app

COPY mix.exs mix.lock ./
COPY config config/
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix deps.compile

COPY assets/package.json assets/package-lock.json ./assets/
RUN npm ci --prefix ./assets

COPY . .
RUN mix deps.clean mime --build && \
    mix assets.deploy && \
    mix release

FROM alpine:3.21
ENV HOME=/opt/app
ENV LANG=C.UTF-8

RUN apk add --no-cache openssl ncurses-libs libstdc++ libgcc

WORKDIR ${HOME}

COPY --from=build /app/_build/prod/rel/keila ${HOME}
COPY ops/inetrc ${HOME}/inetrc
COPY ops/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    adduser -s /bin/sh -u 1001 -G root -h ${HOME} -S -D default && \
    chown -R 1001:0 ${HOME}

ENV ERL_INETRC=${HOME}/inetrc

ARG PORT=4000
ENV PORT=${PORT}
EXPOSE ${PORT}/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD []
