#!/usr/bin/env bash

set -e

cd /build

APP_NAME="$(grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g')"
APP_VSN="$(grep 'version:' mix.exs | cut -d '"' -f2)"

mkdir -p /build/rel/artifacts

# Install updated versions of hex/rebar
mix local.rebar --force
mix local.hex --if-missing --force

export MIX_ENV=prod

# Fetch deps and compile
mix do deps.get --only prod
# Run an explicit clean to remove any build artifacts from the host
mix do clean, compile --force
# Build the release
mix distillery.release
# Copy tarball to output
cp "_build/prod/rel/$APP_NAME/releases/$APP_VSN/$APP_NAME.tar.gz" rel/artifacts/"$APP_NAME-$APP_VSN.tar.gz"
