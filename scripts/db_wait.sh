#!/bin/bash

set -e

while ! nc -z localhost $DATABASE_PORT; do
  sleep 0.1 # wait for 1/10 of the second before check again
done
