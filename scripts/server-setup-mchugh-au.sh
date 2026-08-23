#!/bin/bash
set -euo pipefail

# One-time provisioning for the mchugh.au static site. Run once as root:
#
#   curl -fsSL https://raw.githubusercontent.com/exploded/mchugh-au/main/scripts/server-setup-mchugh-au.sh | sudo bash
#
# Safe to re-run. Leaves the existing Caddy block for mchugh.au alone — it
# already serves $WEB_ROOT correctly.

WEB_ROOT="/var/www/mchugh.au"
DEPLOY_USER="deploy"
NAME="mchugh-au"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: run as root (sudo)." >&2
    exit 1
fi

echo "[setup] Web root: $WEB_ROOT"
mkdir -p "$WEB_ROOT"
chown -R www-data:www-data "$WEB_ROOT"

# Install the deploy script. Prefer a copy scp'd alongside this one; otherwise
# fetch it from the repo so a piped curl|bash still works.
echo "[setup] Installing /usr/local/bin/deploy-$NAME"
SRC="$(dirname "$0")/deploy-$NAME"
if [ -f "$SRC" ]; then
    install -m 755 "$SRC" "/usr/local/bin/deploy-$NAME"
else
    curl -fsSL "https://raw.githubusercontent.com/exploded/$NAME/main/scripts/deploy-$NAME" \
        -o "/usr/local/bin/deploy-$NAME"
    chmod 755 "/usr/local/bin/deploy-$NAME"
fi

# Sudoers: the deploy user may run only this one script, without a password.
echo "[setup] Writing /etc/sudoers.d/$NAME"
cat > "/etc/sudoers.d/$NAME" <<EOF
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/local/bin/deploy-$NAME
EOF
chmod 440 "/etc/sudoers.d/$NAME"
visudo -cf "/etc/sudoers.d/$NAME"

cat <<EOF

[setup] Complete.

  Web root : $WEB_ROOT
  Deploy   : /usr/local/bin/deploy-$NAME
  Sudoers  : /etc/sudoers.d/$NAME

Deploys now run from GitHub Actions on push to main.
Manual run: sudo /usr/local/bin/deploy-$NAME /tmp/mchugh-au-deploy

Please also report the output of:  ls -la $WEB_ROOT
EOF
