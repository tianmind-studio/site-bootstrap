{{domain}} {
    encode gzip zstd
    reverse_proxy 127.0.0.1:{{port}}

    header {
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
    }
}
