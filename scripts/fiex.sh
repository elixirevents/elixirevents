#!/bin/bash

set -e

fly ssh console --pty --select -C "/app/bin/elixir_events remote"
