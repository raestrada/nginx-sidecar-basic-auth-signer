FROM nginx:alpine
MAINTAINER "Rodrigo Estrada <rodrigo.estrada@gmail.com>"

# --------------------
# METADATA
# --------------------
EXPOSE 8087
ENV NGINX_VERSION=1.12.2 \
  DOCKERIZE_VERSION=v0.6.1 \
  PORT=8087 \
  FORWARD_HOST=localhost \
  FORWARD_PORT=8080 \
  BASIC_AUTH_USERNAME=admin \
  BASIC_AUTH_PASSWORD=admin \
  PROXY_READ_TIMEOUT=60s \
  PROXY_SEND_TIMEOUT=60s \
  CLIENT_MAX_BODY_SIZE=1m \
  PROXY_REQUEST_BUFFERING=on \
  PROXY_BUFFERING=on

# --------------------
# DEPENDENCIES
# --------------------
RUN wget -O dockerize.tar.gz https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
  && tar -C /usr/local/bin -xzvf dockerize.tar.gz \
  && apk add --update --no-cache --virtual entrypoint apache2-utils curl \
  && rm dockerize.tar.gz /etc/nginx/conf.d/default.conf /etc/nginx/nginx.conf \
  && mkdir /templates \
  && chmod g+rw /etc/nginx /etc/nginx/conf.d /templates

# --------------------
# CERTIFICATES
# --------------------

RUN curl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/local/bin/cfssl \
  && curl https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/local/bin/cfssljson \
  && chmod +x /usr/local/bin/cfssl /usr/local/bin/cfssljson

COPY include/generate_ca.sh /

RUN /bin/sh /generate_ca.sh

# --------------------
# TEMPLATES
# --------------------
COPY default.conf.tpl nginx.conf.tpl /templates/

# --------------------
# FILL TEMPLATES & GO
# --------------------
CMD HTTPPASSWD="$(printf "$BASIC_AUTH_USERNAME:$BASIC_AUTH_PASSWORD" | base64)" dockerize \
    -template /templates/default.conf.tpl:/etc/nginx/conf.d/default.conf \
    -template /templates/nginx.conf.tpl:/etc/nginx/nginx.conf \
    nginx
