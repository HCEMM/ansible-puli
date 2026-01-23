## Troubleshoot

Nginx logs are at `/var/log/nginx`.

### Domain name resolution might have a short stroke

It has happened that all services go away at the same time. This is caused by some overwhelming requests to nginx, but it eventually goes away.

If services are still available at their `IP:port` addresses, but unavailable at their domain names, I had some good results by configuring these options for the troubling website:
```
location / {
    proxy_pass http://website;

    proxy_http_version 1.1;
    proxy_set_header Connection "";

    proxy_connect_timeout 5s;
    proxy_send_timeout    60s;
    proxy_read_timeout    60s;

    send_timeout          60s;

    proxy_next_upstream error timeout http_502 http_503 http_504;
}
```
