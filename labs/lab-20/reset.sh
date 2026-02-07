#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
if [[ -z "${mode}" ]]; then
  echo "Usage: ./reset.sh mode-a|mode-b" >&2
  exit 1
fi
if [[ "${mode}" != "mode-a" && "${mode}" != "mode-b" ]]; then
  echo "ERROR: mode must be mode-a or mode-b" >&2
  exit 1
fi

[[ -f ".env" ]] || { echo "ERROR: .env not found. Create it from .env.example first." >&2; exit 1; }

good_ref="$(grep -E '^KNOWN_GOOD_IMAGE_REF=' .env | head -n1 | cut -d= -f2- | tr -d '\r\n')"
promoted="$(grep -E '^PROMOTED_IMAGE_REF=' .env | head -n1 | cut -d= -f2- | tr -d '\r\n')"

if [[ "${good_ref}" == "REPLACE_ME" || "${promoted}" == "REPLACE_ME" || -z "${good_ref}" || -z "${promoted}" ]]; then
  echo "ERROR: Set KNOWN_GOOD_IMAGE_REF and PROMOTED_IMAGE_REF in .env before starting the incident." >&2
  echo "Hint: docker image inspect dzth/mini-platform-api:${RC_VERSION} --format '{{.Id}}'" >&2
  exit 1
fi

# Always start from known-good baseline first (restore stable values)
tmp="$(mktemp)"
sed -E "s/^DB_HOST=.*/DB_HOST=db/" .env \
  | sed -E "s/^PROMOTED_IMAGE_REF=.*/PROMOTED_IMAGE_REF=${good_ref//\//\\/}/" \
  > "${tmp}"
mv "${tmp}" .env

if [[ "${mode}" == "mode-a" ]]; then
  # Break DB wiring
  tmp="$(mktemp)"
  sed -E "s/^DB_HOST=.*/DB_HOST=db-broken/" .env > "${tmp}"
  mv "${tmp}" .env
  echo "mode-a" > break-mode.txt
  echo "Incident started: mode-a (misconfiguration: DB_HOST wrong)"
else
  # Break promotion discipline
  tmp="$(mktemp)"
  sed -E "s/^PROMOTED_IMAGE_REF=.*/PROMOTED_IMAGE_REF=sha256:0000000000000000000000000000000000000000000000000000000000000000/" .env > "${tmp}"
  mv "${tmp}" .env
  echo "mode-b" > break-mode.txt
  echo "Incident started: mode-b (bad promotion: PROMOTED_IMAGE_REF wrong)"
fi

echo "NOTE: Do NOT rebuild images during the incident. Fix by updating .env and restarting the stack."
