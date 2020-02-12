# Upstream
upstream backend {
    server {{ .Env.FORWARD_HOST }}:{{ .Env.FORWARD_PORT }} max_fails=0;
}

# WS Handling
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

# Server Definition
server {
    listen {{ .Env.PORT }};

{{ if .Env.WEBSOCKET_PATH }}
    location {{ .Env.WEBSOCKET_PATH }} {
        proxy_pass http://backend{{ .Env.FORWARD_WEBSOCKET_PATH | default "" }};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
        proxy_read_timeout {{ .Env.PROXY_READ_TIMEOUT }};
        proxy_send_timeout {{ .Env.PROXY_SEND_TIMEOUT }};
    }
{{ end }}

    location / {
        # Proxy
{{ if .Env.SSL }}
        proxy_ssl_certificate /certificates/mitm.crt;
        proxy_ssl_certificate_key /certificates/mitm.key;
        proxy_ssl_protocols           TLSv1 TLSv1.1 TLSv1.2;
        proxy_ssl_ciphers             HIGH:!aNULL:!MD5;
        # proxy_ssl_trusted_certificate /certificates/mitm.crt;
        # proxy_ssl_verify on;
        proxy_ssl_session_reuse on;
        proxy_set_header Authorization "Basic {{ .Env.HTTPPASSWD }}";
        proxy_set_header Host {{ .Env.FORWARD_HOST }};
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
        proxy_pass https://backend;
{{ else }}
        proxy_pass http://backend; 
{{ end }}
        proxy_read_timeout {{ .Env.PROXY_READ_TIMEOUT }};
        proxy_send_timeout {{ .Env.PROXY_SEND_TIMEOUT }};
        client_max_body_size {{ .Env.CLIENT_MAX_BODY_SIZE }};
        proxy_request_buffering {{ .Env.PROXY_REQUEST_BUFFERING }};
        proxy_buffering {{ .Env.PROXY_BUFFERING }};
    }
}
