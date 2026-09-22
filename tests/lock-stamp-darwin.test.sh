#!/bin/bash
# The remote lock stamp must be built without GNU hostname or GNU date.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)

set +e
hostname --fqdn >"$work/hn.out" 2>"$work/hn.err"
hn=$?
date --utc --rfc-2822 >"$work/dt.out" 2>"$work/dt.err"
dt=$?
set -e
if [ "$hn" -eq 0 ] || [ "$dt" -eq 0 ]; then
  echo "GNU forms unexpectedly succeeded (hostname $hn, date $dt)" >&2
  exit 1
fi
grep -q "illegal option" "$work/hn.err"
grep -q "illegal option" "$work/dt.err"

funcs=$(awk '
  /^host_fqdn\(\) \{/ {p=1}
  /^utc_rfc2822\(\) \{/ {p=1}
  p {print}
  /^}$/ && p {c++; if (c==2) exit}
' "$root/git-ftp")
# shellcheck disable=SC1090
eval "$funcs"
fqdn=$(host_fqdn)
stamp=$(utc_rfc2822)
[ -n "$fqdn" ]
printf '%s\n' "$stamp" | grep -Eq '^[A-Z][a-z]{2}, [0-9]{2} [A-Z][a-z]{2} [0-9]{4} '
echo "git-ftp lock stamp darwin ok (hostname $hn, date $dt, fqdn $fqdn, stamp $stamp)"
rm -rf "$work"
