server {
    listen 80;
    listen [::]:80;
    server_name {{domain}};

    root /var/www/{{domain}};
    index index.html;

    # SPA-friendly fallback; drop the /index.html piece for pure static if undesired.
    location / {
        try_files $uri $uri/ /index.html =404;
    }

    # Long-cache immutable assets.
    location ~* \.(js|css|png|jpg|jpeg|gif|webp|avif|ico|svg|woff|woff2|ttf|eot|mp4|webm)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Minimal security headers. Tune CSP for your app.
    add_header X-Frame-Options        "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff"     always;
    add_header Referrer-Policy        "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy     "camera=(), microphone=(), geolocation=()" always;

    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript image/svg+xml;
}
