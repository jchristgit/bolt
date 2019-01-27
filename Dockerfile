FROM elixir:1.8-alpine

ENV MIX_ENV=prod

RUN apk add --no-cache --virtual .build-deps git && apk add --no-cache bash

WORKDIR /app

# Set up dependencies in an extra step to ensure
# that in most cases (only updating the source code,
# and not the dependencies) we only recompile
# the actual app itself instead of fetching all
# dependencies and compiling them first.

COPY mix.exs mix.lock ./
RUN mix do local.hex --force, \
           local.rebar --force, \
           deps.get, \
           deps.compile

COPY . /app
RUN mix release \
    && apk del .build-deps

ENTRYPOINT ["/app/_build/prod/rel/bolt/bin/bolt"]
CMD ["foreground"]
