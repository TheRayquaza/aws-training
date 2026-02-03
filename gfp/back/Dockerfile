FROM golang:1.24-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
# Note: Building from the specific path you provided in the tree
RUN GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o main src/cmd/main.go

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash nonroot

WORKDIR /app
COPY --from=builder /app/main .
COPY --from=builder /app/.env .env

USER nonroot
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://${APP_HOST}:${PORT}/health || exit 1

CMD ["./main"]
