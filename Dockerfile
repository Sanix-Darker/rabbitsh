FROM alpine:latest

RUN apk add bash

WORKDIR /rabbitsh

COPY send.sh consumer.sh /

CMD ["/bin/bash"]
ENTRYPOINT ["/consumer.sh"]
