#!/usr/bin/env bash
#
# Builds the App Suite Seeder web service image for linux/amd64 (x86_64 — the
# usual server architecture) and saves it as a gzipped tarball under
# Binaries/Docker Images, ready to copy to a server and `docker load`.
#
# Usage:   ./build-image.sh
# Override the image tag:   IMAGE=appsuite-seeder:v2 ./build-image.sh
#
set -euo pipefail

IMAGE="${IMAGE:-appsuite-seeder:latest}"

# Resolve paths relative to this script so it works from any working directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/Binaries/Docker Images"
OUTPUT_FILE="$OUTPUT_DIR/appsuite-seeder.tar.gz"

command -v docker >/dev/null 2>&1 || { echo "Error: Docker is not installed or not on PATH." >&2; exit 1; }

mkdir -p "$OUTPUT_DIR"

echo "==> Building $IMAGE for linux/amd64 (this uses emulation on Apple Silicon)…"
docker buildx build \
    --platform linux/amd64 \
    -f "$REPO_ROOT/webservice/Dockerfile" \
    -t "$IMAGE" \
    --load \
    "$REPO_ROOT"

echo "==> Saving image to: $OUTPUT_FILE"
docker save "$IMAGE" | gzip > "$OUTPUT_FILE"

echo
echo "Done — $(du -h "$OUTPUT_FILE" | cut -f1) written to:"
echo "  $OUTPUT_FILE"
echo
echo "Deploy to a server that has Docker:"
echo "  gunzip -c \"$OUTPUT_FILE\" | ssh USER@HOST 'docker load'"
echo "  ssh USER@HOST 'docker run -d --restart unless-stopped -p 8080:8080 --name seeder $IMAGE'"
