#!/bin/bash

set -ex

# Wait until the connection is available or timeout after 10 seconds
timeout 10 /scripts/db_wait.sh

source /scripts/set_env.sh

if rails db:exists DATABASE_USER=deployer
then
    DATABASE_USER=$DATABASE_OWNER rails db:migrate
else
    # create a database using the deployer account and set the
    # ownership to the service user
    DATABASE_USER=deployer rails db:create
    DATABASE_USER=deployer rails db:alter_owner
    DATABASE_USER=deployer rails db:add_extensions
    DATABASE_USER=$DATABASE_OWNER rails db:migrate
    DATABASE_USER=$DATABASE_OWNER rails db:seed
fi
