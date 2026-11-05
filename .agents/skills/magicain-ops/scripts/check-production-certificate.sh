#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${1:-magicain.com}"
SSH_TARGET="${2:-prod-app-frontend}"
WARN_DAYS="${WARN_DAYS:-30}"
WARN_SECONDS=$((WARN_DAYS * 86400))

print_cert_metadata() {
  openssl x509 -noout \
    -subject \
    -issuer \
    -dates \
    -ext subjectAltName \
    -fingerprint -sha256
}

check_expiry() {
  local label="$1"
  local cert_pem="$2"

  if printf '%s\n' "$cert_pem" | openssl x509 -checkend "$WARN_SECONDS" -noout >/dev/null 2>&1; then
    printf '%s: valid for more than %s days\n' "$label" "$WARN_DAYS"
  else
    printf '%s: expires within %s days or is already expired\n' "$label" "$WARN_DAYS"
  fi
}

printf 'Public endpoint: %s\n' "$DOMAIN"
if PUBLIC_CERT="$(openssl s_client -connect "${DOMAIN}:443" -servername "$DOMAIN" </dev/null 2>/dev/null)" \
  && printf '%s\n' "$PUBLIC_CERT" | openssl x509 -noout >/dev/null 2>&1; then
  printf '%s\n' "$PUBLIC_CERT" | print_cert_metadata
  check_expiry "public" "$PUBLIC_CERT"
else
  printf 'Public TLS probe failed. Check DNS, network, and ICP filing separately.\n'
fi

printf '\nProduction server via SSH: %s\n' "$SSH_TARGET"
if REMOTE_CERT="$(ssh -o BatchMode=yes -o ConnectTimeout=8 "$SSH_TARGET" \
  "openssl s_client -connect 127.0.0.1:443 -servername '$DOMAIN' </dev/null 2>/dev/null" 2>/dev/null)" \
  && printf '%s\n' "$REMOTE_CERT" | openssl x509 -noout >/dev/null 2>&1; then
  printf '%s\n' "$REMOTE_CERT" | print_cert_metadata
  check_expiry "production" "$REMOTE_CERT"
else
  printf 'Production SSH/TLS probe failed. Verify the SSH alias and server access.\n'
  exit 1
fi
