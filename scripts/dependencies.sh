#!/bin/bash

set -ex


BUILD_PACKAGES=$(echo \
                     apt-transport-https \
                     curl \
                     gnupg \
                     gnupg2 \
                     software-properties-common \
                     lsb-release)

RUNTIME_PACKAGES=$(echo \
                       awscli \
                       git \
                       ca-certificates \
                       build-essential \
                       postgresql-client \
                       netcat \
                       gettext)


apt-get update -y
apt-get install -y $BUILD_PACKAGES
apt-get install -y $RUNTIME_PACKAGES

# # Install gcloud
# export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
# echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
# curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
# apt-get update -y && apt-get install google-cloud-sdk -y

# Install kubectl
touch /etc/apt/sources.list.d/kubernetes.list
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl

# Install Helm
HELM_VERSION=v2.10.0
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh --version $HELM_VERSION
helm init --client-only
helm plugin install https://github.com/chartmuseum/helm-push

# Install Docker

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update -y
apt-get install docker-ce -y

# Install RVM

# See: https://github.com/inversepath/usbarmory-debian-base_image/issues/9#issuecomment-451635505
mkdir ~/.gnupg
echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf
#
for keyserver in hkp://pool.sks-keyservers.net hkp://ipv4.pool.sks-keyservers.net hkp://pgp.mit.edu hkp://keyserver.pgp.com
do
    gpg2 --keyserver $keyserver --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && break
done
curl -sSL https://get.rvm.io | bash -s stable --gems=thor

# clean up
apt-get remove --purge -y $BUILD_PACKAGES
export SUDO_FORCE_REMOVE=yes
apt-get autoremove --purge -y
# just incase a dependency was auto removed
apt-get install -y $RUNTIME_PACKAGES --no-install-recommends
rm -rf /var/lib/apt/lists/*
