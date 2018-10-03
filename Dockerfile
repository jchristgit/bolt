FROM elixir:1.6-alpine

RUN apk add --no-cache \
        git \
        tini

RUN addgroup bolt \
    && \
    adduser bolt -G bolt -D

WORKDIR /app

# Set up dependencies in an extra step to ensure
# that in most cases (only updating the source code,
# and not the dependencies) we only recompile
# the actual app itself instead of fetching all
# dependencies and compiling them first.
ENV MIX_ENV prod
ENV MIX_HOME /home/bolt
RUN mix do local.hex --force, \
           local.rebar --force
COPY mix.exs mix.exs
COPY mix.lock mix.lock
RUN mix do deps.get, \
           deps.compile

COPY . /app
RUN mix compile

USER bolt

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["mix", "run", "--no-halt"]
