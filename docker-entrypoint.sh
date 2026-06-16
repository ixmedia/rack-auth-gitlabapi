#!/bin/bash
set -e

# Install gems of project
# Needed on windows.
bundle install --jobs $(nproc)

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
