# DeployTag

Docker Image used to deploy micro services

The machine consists of:
- build-essential
- docker
- ruby

## Deployment Scripts
A collection of scripts that can be used to build/deploy a micro service

- /scripts/deploy.sh
- /scripts/auth.sh
- /scripts/build.sh

## Release Script
This script can be used to tag a release which will trigger a build and deployment to `beta` or `production`
```
# For details on available options
/scripts/release help
```
