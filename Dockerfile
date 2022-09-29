FROM alpine:3.16@sha256:bc41182d7ef5ffc53a40b044e725193bc10142a1243f395ee852a8d9730fc2ad

ENV kubectl_version=v1.25.2 \
    kubectl_checksum=8639f2b9c33d38910d706171ce3d25be9b19fc139d0e3d4627f38ce84f9040eb

ENV helm_version=v3.10.0 \
    helm_checksum=bc102ba0c9d5fba18b520fbedf63d114e47426a6b6aa0337ecab4a327704d6ab

ENV stern_version=1.22.0 \
    stern_checksum=cecafc0110310118fb77c0d9bcc7af8852fe4cfd8252d096b070c647b70d1cd9

RUN apk add --no-cache \
    bash \
    py3-pip &&\
    pip install --no-cache 'awscli>=1.25'

RUN wget -q https://storage.googleapis.com/kubernetes-release/release/${kubectl_version}/bin/linux/amd64/kubectl -O /tmp/kubectl &&\
    wget -q https://get.helm.sh/helm-${helm_version}-linux-amd64.tar.gz -O - | tar xzf - -C /tmp/ --strip-components=1 linux-amd64/helm &&\
    wget -q https://github.com/stern/stern/releases/download/v${stern_version}/stern_${stern_version}_linux_amd64.tar.gz -O - | tar xzf - -C /tmp/  &&\
    sha256sum /tmp/kubectl | grep -q ${kubectl_checksum} &&\
    sha256sum /tmp/helm | grep -q ${helm_checksum} &&\
    sha256sum /tmp/stern | grep -q ${stern_checksum} &&\
    chmod +x /tmp/kubectl /tmp/helm /tmp/stern &&\
    mv /tmp/kubectl /tmp/helm /tmp/stern /usr/local/bin/ &&\
    rm -rf /tmp/* &&\
    touch /tmp/config &&\
    chmod 600 /tmp/config

ENV KUBECONFIG=/tmp/config

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
