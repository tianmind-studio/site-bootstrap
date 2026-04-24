# lib/new.sh — scaffold a new project with an interactive site.yaml.
# shellcheck shell=bash

sb_cmd_new() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    sb_err "usage: site-bootstrap new <name>"
    return 2
  fi

  if [[ -d "$name" ]]; then
    sb_err "directory already exists: $name"
    return 1
  fi

  sb_step "Scaffolding $name"

  # Interactive prompts — each has a sensible default.
  local default_domain="$name.example.com"
  local default_server="my-vps"

  read -r -p "  domain       [$default_domain]: " input_domain
  read -r -p "  ssh alias    [$default_server]: " input_server
  local type_input
  read -r -p "  project type [static/node] (static): " type_input

  local domain="${input_domain:-$default_domain}"
  local server="${input_server:-$default_server}"
  local type="${type_input:-static}"

  case "$type" in
    static|node) ;;
    *) sb_err "unsupported type: $type (use 'static' or 'node')"; return 1 ;;
  esac

  local build="" port=3000 source_dir="."
  if [[ "$type" == "node" ]]; then
    read -r -p "  build command [pnpm build]: " input_build
    read -r -p "  listen port   [3000]: " input_port
    build="${input_build:-pnpm build}"
    port="${input_port:-3000}"
  else
    read -r -p "  build output  [. for plain HTML, dist for astro]: " input_out
    source_dir="${input_out:-.}"
  fi

  local cf_proxied
  read -r -p "  proxy through Cloudflare? [y/N]: " cf_proxied
  local proxied="false"
  [[ "$cf_proxied" =~ ^[Yy] ]] && proxied="true"

  sb_run mkdir -p "$name"

  # Write site.yaml
  if [[ "${SB_DRY_RUN:-0}" == "1" ]]; then
    sb_info "(dry-run) would write $name/site.yaml with the above values"
    return 0
  fi

  {
    printf 'name: %s\n' "$name"
    printf 'domain: %s\n' "$domain"
    printf 'server: %s  # matches an alias in your ~/.ssh/config\n' "$server"
    printf 'deploy:\n'
    printf '  type: %s\n' "$type"
    if [[ "$type" == "static" ]]; then
      printf '  source: %s\n' "$source_dir"
      printf '  # build: pnpm build  # uncomment if you need a build step\n'
    else
      printf '  source: .\n'
      printf '  build: %s\n' "$build"
      printf '  port: %s\n' "$port"
    fi
    printf 'ssl:\n'
    printf '  provider: letsencrypt\n'
    printf '  # email: you@example.com  # optional; will use --register-unsafely-without-email if unset\n'
    printf 'dns:\n'
    printf '  provider: cloudflare\n'
    printf '  proxied: %s\n' "$proxied"
    printf 'nginx:\n'
    printf '  # template: static | proxy  (auto-detected from deploy.type)\n'
    printf '  # custom: /absolute/path/to/your-template.conf.tpl\n'
  } > "$name/site.yaml"

  # Starter index.html for static sites so deploy works end-to-end out of the box.
  if [[ "$type" == "static" ]]; then
    cat > "$name/index.html" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>$name</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: system-ui, sans-serif; max-width: 640px; margin: 4rem auto; padding: 0 1rem; color: #222; }
    code { background: #f4f4f4; padding: 0.1em 0.4em; border-radius: 4px; }
  </style>
</head>
<body>
  <h1>$name</h1>
  <p>Scaffolded by <code>site-bootstrap</code>. Edit <code>index.html</code>, then run:</p>
  <pre><code>site-bootstrap deploy</code></pre>
</body>
</html>
EOF
  fi

  # Gitignore with sensible defaults.
  cat > "$name/.gitignore" <<'EOF'
node_modules/
dist/
build/
.next/
.env
.env.local
.DS_Store
._*
EOF

  # .env template for Cloudflare credentials (gitignored).
  cat > "$name/.env.example" <<'EOF'
# Cloudflare API credentials (scope: Zone:DNS:Edit)
# Copy to .env and fill in. site-bootstrap loads .env automatically.
CF_API_TOKEN=
CF_ZONE_ID=
EOF

  sb_ok "created $name/"
  sb_info "next:"
  sb_info "  cd $name"
  sb_info "  cp .env.example .env   # add Cloudflare token if you want DNS automation"
  sb_info "  site-bootstrap deploy"
}
