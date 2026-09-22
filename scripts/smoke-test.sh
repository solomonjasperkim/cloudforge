#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:?usage: ./scripts/smoke-test.sh http://host}"

curl --fail --silent --show-error "$BASE_URL/health"
curl --fail --silent --show-error "$BASE_URL/"
