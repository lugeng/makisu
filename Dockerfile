FROM golang:1.11 AS builder

RUN mkdir -p /go/src/github.com/uber/makisu
WORKDIR /go/src/github.com/uber/makisu

ADD Makefile .
RUN make ext-tools/Linux/dep

ADD Gopkg.toml Gopkg.lock ./
ADD .git ./.git
ADD bin ./bin
ADD lib ./lib
RUN make lbins


FROM golang:1.11 AS gcr_cred_helper_builder
RUN go get -u github.com/GoogleCloudPlatform/docker-credential-gcr
RUN CGO_ENABLED=0 make -C /go/src/github.com/GoogleCloudPlatform/docker-credential-gcr && \
    cp /go/src/github.com/GoogleCloudPlatform/docker-credential-gcr/bin/docker-credential-gcr /docker-credential-gcr


FROM golang:1.11 AS ecr_cred_helper_builder
RUN go get -u github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login
RUN make -C /go/src/github.com/awslabs/amazon-ecr-credential-helper linux-amd64


FROM scratch
COPY --from=builder /go/src/github.com/uber/makisu/bin/makisu/makisu.linux /makisu-internal/makisu
ADD ./assets/cacerts.pem /makisu-internal/certs/cacerts.pem

COPY --from=gcr_cred_helper_builder /docker-credential-gcr /makisu-internal/docker-credential-gcr
COPY --from=ecr_cred_helper_builder /go/src/github.com/awslabs/amazon-ecr-credential-helper/bin/linux-amd64/docker-credential-ecr-login /makisu-internal/docker-credential-ecr-login
ENTRYPOINT ["/makisu-internal/makisu"]
