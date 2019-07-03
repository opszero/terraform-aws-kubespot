#!/bin/bash

set -e

gem install bundler -v "$(cat Gemfile.lock | grep -A 1 "BUNDLED WITH" | grep -v BUNDLED | awk '{print $1}')"

bundle config github.com $GITHUB_TOKEN:x-oauth-basic

if bundle check
then
    echo ""
else
    if [ "$RAILS_ENV" = "development" ] || [ "$RAILS_ENV" = "test" ] || [ "$RAILS_ENV" = "" ]
    then
        bundle install
    else
        bundle config --global frozen 1
        bundle install --without development test
    fi
fi
