{{domain}} {
    root * /var/www/{{domain}}
    encode gzip zstd
    file_server
    try_files {path} {path}/ /index.html

    header {
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
    }

    @assets path *.js *.css *.png *.jpg *.jpeg *.gif *.webp *.avif *.ico *.svg *.woff *.woff2
    header @assets Cache-Control "public, max-age=2592000, immutable"
}
