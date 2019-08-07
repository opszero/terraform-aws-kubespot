FROM golang:latest

COPY scripts/dependencies.sh /scripts/
RUN /scripts/dependencies.sh

COPY scripts /scripts
COPY rails /rails

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o /bin/deploytag
