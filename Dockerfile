FROM ubuntu:18.04

COPY scripts/dependencies.sh /scripts/
RUN /scripts/dependencies.sh


COPY scripts /scripts
COPY rails /rails
