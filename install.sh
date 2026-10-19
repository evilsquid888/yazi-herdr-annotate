#!/usr/bin/env bash
# Install the Yazi -> herdr-annotate opener.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
ydir="${YAZI_CONFIG_HOME:-$HOME/.config/yazi}"
conf="$ydir/yazi.toml"

for cmd in herdr yazi jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "missing dependency: $cmd" >&2; exit 1; }
done

mkdir -p "$ydir"
install -m 0755 "$here/annotate-open.sh" "$ydir/annotate-open.sh"
echo "installed $ydir/annotate-open.sh"

if [ -f "$conf" ] && grep -q 'annotate-open.sh' "$conf"; then
  echo "$conf already has the annotate opener; left unchanged"
elif [ -f "$conf" ] && grep -qE '^\[(opener|open)\]' "$conf"; then
  echo "$conf already has an [opener] or [open] table." >&2
  echo "Merge $here/yazi-annotate.toml into it by hand (TOML tables can't be repeated)." >&2
  exit 1
else
  [ -f "$conf" ] && cp "$conf" "$conf.bak-$(date +%Y%m%d-%H%M%S)"
  { [ -s "$conf" ] && echo; cat "$here/yazi-annotate.toml"; } >> "$conf"
  echo "added the annotate opener to $conf"
fi

keys="$ydir/keymap.toml"
if [ -f "$keys" ] && grep -q 'plugin toggle-pane' "$keys"; then
  echo "$keys already has toggle-pane keys; left unchanged"
else
  if ! ya pkg list 2>/dev/null | grep -q 'toggle-pane'; then
    ya pkg add yazi-rs/plugins:toggle-pane
  fi
  [ -f "$keys" ] && cp "$keys" "$keys.bak-$(date +%Y%m%d-%H%M%S)"
  { [ -s "$keys" ] && echo; cat "$here/yazi-keymap.toml"; } >> "$keys"
  echo "added T column-toggle keys to $keys"
fi

echo
echo "Next:"
echo "  herdr plugin install plannotator/herdr-annotate   # Full variant"
echo "  herdr plugin install speardragon/herdr-yazi"
echo "  add herdr-keys.toml to ~/.config/herdr/config.toml, then: herdr server reload-config"
echo "Restart Yazi to load the new opener."
