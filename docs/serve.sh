#!/bin/bash
# Kör Jekyll lokalt. Installerar gems i docs/vendor/bundle/ om de saknas.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

bundle config set --local path 'vendor/bundle'
bundle install --quiet
bundle exec jekyll serve --livereload
