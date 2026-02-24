#!/usr/bin/env bash
# Setup a shared PostgreSQL 17 container on the Hetzner server.
# Run once on the server as appuser.
#
# Usage: ssh appuser@<server> 'bash -s' < setup/pg_install.sh <postgres_password>

set -euo pipefail

POSTGRES_PASSWORD="${1:?Usage: $0 <postgres_password>}"
CONTAINER_NAME="postgres"
PG_VERSION="17"
VOLUME_NAME="pgdata"

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Container '${CONTAINER_NAME}' already exists. Remove it first if you want to recreate."
  exit 1
fi

echo "Creating Docker volume '${VOLUME_NAME}'..."
docker volume create "${VOLUME_NAME}"

echo "Starting PostgreSQL ${PG_VERSION} container..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p 127.0.0.1:5432:5432 \
  -v "${VOLUME_NAME}":/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
  "postgres:${PG_VERSION}"

echo "Waiting for PostgreSQL to be ready..."
for i in $(seq 1 30); do
  if docker exec "${CONTAINER_NAME}" pg_isready -U postgres > /dev/null 2>&1; then
    echo "PostgreSQL is ready."
    break
  fi
  sleep 1
done

echo "Creating databases..."
docker exec "${CONTAINER_NAME}" createdb -U postgres eventer_production
docker exec "${CONTAINER_NAME}" createdb -U postgres eventer_qa

echo ""
echo "Done. Add this to your eventer.env:"
echo "  DATABASE_URL=\"postgresql://postgres:${POSTGRES_PASSWORD}@host.docker.internal:5432/eventer_production\""
echo ""
echo "To create databases for other apps:"
echo "  docker exec postgres createdb -U postgres <db_name>"
