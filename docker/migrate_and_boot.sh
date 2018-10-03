#!/bin/ash

mix do ecto.create --quiet, ecto.migrate --quiet
mix run --no-halt
