# build an image with terraform
FROM --platform=$BUILDPLATFORM alpine:3.17

ARG BUILDPLATFORM
ARG TARGETARCH
ARG TERRAFORM_VERSION
ENV TERRAFORM_VERSION ${TERRAFORM_VERSION:-1.3.9}

WORKDIR /root

# install terraform
RUN apk add --no-cache curl unzip git \
    && curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip -o terraform.zip \
    && unzip terraform.zip \
    && chmod +x terraform \
    && mv terraform /usr/local/bin/ \
    && curl -sL https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/${TARGETARCH}/kubectl -o kubectl \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

CMD [ "terraform" ]