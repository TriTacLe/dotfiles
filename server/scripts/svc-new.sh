#!/bin/bash
# Provision a new service slot under /srv/<name>/.
#
# Creates:
#   - System user `svc_<name>` (no shell, no password, no home)
#   - /srv/<name>/data/   owned by svc_<name>:svc_<name>, mode 750
#   - /srv/<name>/.env    with PUID/PGID for the service user (owned by you)
#   - /srv/<name>/compose.yml stub if missing (owned by you)
#
# Needs sudo. Idempotent: re-running for an existing service is safe.
#
# Usage: sudo bash svc-new.sh <name>

set -e

NAME="$1"
if [[ -z "$NAME" || ! "$NAME" =~ ^[a-z][a-z0-9_-]{0,30}$ ]]; then
    echo "usage: sudo bash svc-new.sh <name>"
    echo "  name must be lowercase alphanumeric (plus _ or -), starting with a letter"
    exit 1
fi

USER_NAME="svc_$NAME"
SRV_DIR="/srv/$NAME"
ADMIN_USER="${SUDO_USER:-tri}"
ADMIN_GROUP="$(id -gn "$ADMIN_USER")"

# 1. Create system user if missing
if ! id -u "$USER_NAME" &>/dev/null; then
    useradd --system --no-create-home --shell /usr/sbin/nologin "$USER_NAME"
    echo "created user $USER_NAME (uid $(id -u "$USER_NAME"))"
else
    echo "user $USER_NAME already exists"
fi

PUID=$(id -u "$USER_NAME")
PGID=$(id -g "$USER_NAME")

# 2. Service dir + data dir
mkdir -p "$SRV_DIR/data"
chown "$ADMIN_USER:$ADMIN_GROUP" "$SRV_DIR"
chown "$USER_NAME:$USER_NAME" "$SRV_DIR/data"
chmod 750 "$SRV_DIR/data"

# 3. .env stub (only if missing)
if [[ ! -f "$SRV_DIR/.env" ]]; then
    cat > "$SRV_DIR/.env" <<EOF
# Service user IDs — pass to the container via PUID/PGID or user: directive.
PUID=$PUID
PGID=$PGID
TZ=Europe/Oslo
EOF
    chown "$ADMIN_USER:$ADMIN_GROUP" "$SRV_DIR/.env"
    chmod 640 "$SRV_DIR/.env"
    echo "wrote $SRV_DIR/.env"
fi

# 4. compose.yml stub (only if missing)
if [[ ! -f "$SRV_DIR/compose.yml" ]]; then
    cat > "$SRV_DIR/compose.yml" <<EOF
# $NAME service stack. Edit me.
# Container runs as PUID:PGID (svc_$NAME) so data/ on the host stays
# owned by that user, not root and not your admin user.
services:
  $NAME:
    image: # TODO: pick image
    container_name: $NAME
    restart: unless-stopped
    user: "\${PUID}:\${PGID}"
    env_file: .env
    volumes:
      - ./data:/data
    # ports:
    #   - "127.0.0.1:XXXX:XXXX"   # bind to localhost; reverse-proxy via nginx or cloudflared
EOF
    chown "$ADMIN_USER:$ADMIN_GROUP" "$SRV_DIR/compose.yml"
    echo "wrote $SRV_DIR/compose.yml stub"
fi

echo
echo "Service '$NAME' ready:"
echo "  user:  $USER_NAME (uid $PUID, gid $PGID)"
echo "  dir:   $SRV_DIR"
echo "  data:  $SRV_DIR/data  (owned by $USER_NAME)"
echo
echo "Next: edit $SRV_DIR/compose.yml, then 'cd $SRV_DIR && docker compose up -d'"
