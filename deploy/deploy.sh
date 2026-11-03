#!/bin/bash
# Pull-based deploy: if GitHub has a newer release, verify it, back it up to S3,
# deploy it to WildFly, and roll back if the smoke test fails.
set -euo pipefail

REPO="HakeemP210/asset-inventory"
BUCKET="asset-inventory-builds-170010887866"
STATE_DIR="/opt/deploy"
APP="asset-inventory.war"
CLI="/opt/wildfly/bin/jboss-cli.sh --connect"
HEALTH_URL="http://localhost:8080/asset-inventory/api/assets"

LATEST=$(curl -fsS "https://api.github.com/repos/$REPO/releases/latest" | jq -r .tag_name)
CURRENT=$(cat "$STATE_DIR/current-tag" 2>/dev/null || echo "none")
FAILED=$(cat "$STATE_DIR/failed-tag" 2>/dev/null || echo "none")

if [ "$LATEST" = "$CURRENT" ] || [ "$LATEST" = "$FAILED" ]; then
  exit 0
fi 
echo "New release $LATEST found (running: $CURRENT)"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
cd "$WORK_DIR"

curl -fsSLO "https://github.com/$REPO/releases/download/$LATEST/$APP"
curl -fsSLO "https://github.com/$REPO/releases/download/$LATEST/$APP.sha256"
sha256sum -c "$APP.sha256"

aws s3 cp "$APP" "s3://$BUCKET/releases/$LATEST/$APP" --region us-east-2 --only-show-errors

smoke_test() {
  for attempt in $(seq 1 10); do
    if [ "$(curl -s -o /dev/null -w '%{http_code}' "$HEALTH_URL")" = "200" ]; then
      return 0
    fi
    sleep 3
  done
  return 1
}

if $CLI --command="deploy $WORK_DIR/$APP --force" && smoke_test; then
  if [ -f "$STATE_DIR/current.war" ]; then
    cp "$STATE_DIR/current.war" "$STATE_DIR/previous.war"
  fi
  cp "$APP" "$STATE_DIR/current.war"
  echo "$LATEST" > "$STATE_DIR/current-tag"
  echo "Deployed $LATEST"
else
  echo "Deploy of $LATEST failed, rolling back to $CURRENT"
  echo "$LATEST" > "$STATE_DIR/failed-tag"
  if [ -f "$STATE_DIR/current.war" ]; then
    $CLI --command="deploy $STATE_DIR/current.war --name=$APP --force"
  fi
  exit 1
fi 