FROM golang

COPY scripts/dependencies.sh /scripts/
RUN /scripts/dependencies.sh

COPY scripts /scripts
COPY rails /rails

ADD . .
RUN go install
