FROM alpine:3.2
RUN apk add --update nginx && rm -rf /var/cache/apk/*
RUN mkdir -p /tmp/nginx/client-body
RUN adduser -D -g 'www' www
RUN mkdir /www && chown -R www:www /var/lib/nginx && chown -R www:www /www
COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /www/index.html
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]