FROM alpine:latest

RUN apk update && apk add --no-cache bash coreutils procps sysstat

COPY monitor.sh /monitor.sh

RUN chmod +x /monitor.sh

ENV SYSTEM_INTERVAL=5

CMD ["/monitor.sh"]