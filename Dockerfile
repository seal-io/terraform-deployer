FROM --platform=$TARGETPLATFORM alpine:3.17.3

ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

RUN set -eo pipefail; \
    apk add -U --no-cache \
      ca-certificates \
      curl unzip git bash openssh jq \
    ; \
    rm -rf /var/cache/apk/*;

# set locale
RUN set -eo pipefail; \
    apk add -U --no-cache \
      tzdata \
    ; \
    rm -rf /var/cache/apk/*;
ENV LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8'


# get kubectl
RUN KUBECTL_VER="v1.25.5"; \
    curl -sfL https://dl.k8s.io/${KUBECTL_VER}/kubernetes-client-${TARGETOS}-${TARGETARCH}.tar.gz | \
        tar -xvzf - --strip-components=3 --no-same-owner -C /usr/bin/ kubernetes/client/bin/kubectl && \
    ln -s /usr/bin/kubectl /usr/bin/k

# get terraform
RUN TF_VER="1.4.5"; \
    curl -sfL https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_${TARGETARCH}.zip -o /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/bin/ && \
    ln -s /usr/bin/terraform /usr/bin/tf; \
    \
    rm -f /tmp/terraform.zip
ENV TF_LOG=INFO

# run as non-root
RUN adduser -D -h /var/terraform -u 1000 terraform
USER terraform
WORKDIR /var/terraform/workspace

# Prepare .terraformrc
COPY terraformrc /var/terraform/.terraformrc
RUN mkdir -p /var/terraform/.terraform.d/plugins

# prepare provider plugin mirror for built-in templates
COPY mirror-plugins.sh .
RUN ./mirror-plugins.sh

CMD [ "terraform" ]
