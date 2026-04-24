# lib/certbot.sh — thin wrapper around certbot on the remote host.
# shellcheck shell=bash

sb_cmd_cert() {
  local domain="${1:-}"
  if [[ -z "$domain" ]]; then
    if [[ -f "$SB_CONFIG" ]]; then
      domain="$(sb_yaml_get "$SB_CONFIG" domain || true)"
    fi
  fi
  if [[ -z "$domain" ]]; then
    sb_err "usage: site-bootstrap cert <domain>"
    return 2
  fi

  local server ssl_email
  if [[ -f "$SB_CONFIG" ]]; then
    server="$(sb_yaml_get "$SB_CONFIG" server || true)"
    ssl_email="$(sb_yaml_get "$SB_CONFIG" ssl.email || true)"
  fi
  : "${server:?set 'server:' in site.yaml or pass --config}"

  local email_flag="--register-unsafely-without-email"
  [[ -n "${ssl_email:-}" ]] && email_flag="--email $ssl_email"

  sb_step "Issue/renew certificate for $domain on $server"
  sb_run ssh "$server" "certbot --nginx -d $domain --non-interactive --agree-tos --expand $email_flag"
  sb_ok "certificate OK"
}
