#!/usr/bin/env bash
# Build + install DDOS-Shield — Cloud Security Control Center with DDOS-Shield.
#
#   binary        /usr/local/bin/ddos-shield   (real file, so granted non-root users can exec)
#   firewall      /usr/local/lib/ddos-shield/ddos-shield-firewall.sh
#   config        /etc/ddos-shield/config.toml (created if absent)
#   state         /var/lib/ddos-shield/        (registry, ddos/, audit/)
#   access group  'ddos-shield'                (members may run the tool; root always can)
#   sudoers       /etc/sudoers.d/ddos-shield   (granted users auto-elevate)
#   service       ddos-shield.service   (optional headless engine — see below)
#
# Re-run after every code change to redeploy. Idempotent and non-destructive:
# existing AVNI data is migrated forward, never deleted.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/ddos-shield-rs"
BIN=/usr/local/bin/ddos-shield
LIBDIR=/usr/local/lib/ddos-shield
CARGO="${CARGO:-$HOME/.cargo/bin/cargo}"

echo "==> building DDOS-Shield (release)"
( cd "$SRC" && "$CARGO" build --release >/dev/null )

echo "==> directories"
install -d -m 0755 /etc/ddos-shield /var/lib/ddos-shield /var/lib/ddos-shield/ddos /var/lib/ddos-shield/audit /var/log/ddos-shield "$LIBDIR"

echo "==> firewall helper -> $LIBDIR"
install -m 0755 "$REPO/scripts/ddos-shield-firewall.sh" "$LIBDIR/ddos-shield-firewall.sh"

echo "==> 'ddos-shield' access group"
groupadd -f ddos-shield

echo "==> sudoers drop-in (auto-elevation for granted users)"
cat >/etc/sudoers.d/ddos-shield <<'EOF'
# DDOS-Shield control center — members of the 'ddos-shield' group may run the tool as root.
%ddos-shield ALL=(root) NOPASSWD: /usr/local/bin/ddos-shield
EOF
chmod 440 /etc/sudoers.d/ddos-shield
if ! visudo -cf /etc/sudoers.d/ddos-shield >/dev/null; then
  echo "!! sudoers validation failed — removing drop-in"; rm -f /etc/sudoers.d/ddos-shield; exit 1
fi

echo "==> installing binary -> $BIN"
rm -f "$BIN"
install -o root -g root -m 0755 "$SRC/target/release/ddos-shield" "$BIN"

echo "==> initialising firewall (ipset + iptables, migrates legacy AVNI state)"
bash "$LIBDIR/ddos-shield-firewall.sh" restore || true

echo "==> seeding config + arming SHIELD enforcement path"
"$BIN" config init || true
"$BIN" ddos enable || true

# Optional headless engine: keeps the SHIELD running (detect/mitigate/recover/
# audit) even when no TUI is open. The TUI/CLI still work standalone without it.
if [ "${WITH_SERVICE:-0}" = "1" ]; then
  echo "==> installing ddos-shield.service"
  install -m 0644 "$REPO/scripts/ddos-shield.service" /etc/systemd/system/ddos-shield.service
  systemctl daemon-reload
  systemctl enable --now ddos-shield.service
fi

echo
echo "OK — DDOS-Shield installed."
echo "  run the control center:   ddos-shield"
echo "  shield status:            ddos-shield ddos status"
echo "  safe local demo:          ddos-shield ddos simulate http-flood"
echo "  granted users:            $(getent group ddos-shield | cut -d: -f4)"
