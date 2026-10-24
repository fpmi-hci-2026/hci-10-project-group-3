#!/usr/bin/env bash
# Анализ репозитория локальным SonarQube.
# Использование: SONAR_TOKEN=<токен> ./scan.sh ../hci-10-backend-api-group-9
set -euo pipefail
repo="$(cd "${1:?укажите путь к репозиторию}" && pwd)"
docker run --rm \
  -e SONAR_HOST_URL=http://host.docker.internal:9000 \
  -e SONAR_TOKEN="${SONAR_TOKEN:?задайте SONAR_TOKEN}" \
  -v "$repo:/usr/src" \
  sonarsource/sonar-scanner-cli:11
