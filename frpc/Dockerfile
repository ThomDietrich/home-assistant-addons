ARG BUILD_FROM
FROM $BUILD_FROM as builder

RUN sed -i -e 's/v[[:digit:]]\.[[:digit:]]/edge/g' /etc/apk/repositories
RUN apk upgrade --update-cache --available && apk add --no-cache go jq curl git make musl-dev
RUN go version

RUN mkdir -p /root/go/src/github.com/fatedier/frp
RUN git clone https://github.com/fatedier/frp /root/go/src/github.com/fatedier/frp
RUN cd /root/go/src/github.com/fatedier/frp && go build -v -o bin/frpc ./cmd/frpc


FROM $BUILD_FROM 

COPY --from=builder /root/go/src/github.com/fatedier/frp/bin/frpc /frpc
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
