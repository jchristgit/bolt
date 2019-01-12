FROM elixir:1.7-alpine

RUN \
        apk add --no-cache git tini \
    && \
        addgroup bolt \
    && \
        adduser bolt -G bolt -D

WORKDIR /app

# Set up dependencies in an extra step to ensure
# that in most cases (only updating the source code,
# and not the dependencies) we only recompile
# the actual app itself instead of fetching all
# dependencies and compiling them first.
ENV \
    MIX_ENV=prod \
    MIX_HOME=/home/bolt

COPY mix.exs mix.lock ./
RUN mix do local.hex --force, \
           local.rebar --force, \
           deps.get, \
           deps.compile

COPY . /app
RUN mix compile

USER bolt

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["mix", "run", "--no-halt"]
