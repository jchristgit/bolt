FROM elixir:1.6-alpine

RUN apk add git tini

COPY . /app
WORKDIR /app

ENV MIX_ENV prod
ENV MIX_HOME /home/bolt

RUN addgroup bolt && adduser bolt -G bolt -D

RUN mix do local.hex --force, local.rebar --force
RUN mix do deps.get, deps.compile
RUN mix compile

USER bolt

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["mix", "run", "--no-halt"]
