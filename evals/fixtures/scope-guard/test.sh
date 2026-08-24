#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

go test ./...
go build -o bin/scopeguard ./cmd/scopeguard
