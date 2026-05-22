FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

LABEL maintainer="iconik Media AB <info@iconik.io>"

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8

RUN apt-get update && \
    apt-get install -y poppler-utils ghostscript dcraw exiftool locales gettext-base && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ARG REPO_BASE=https://packages.iconik.io/deb/ubuntu

RUN apt-get update && apt-get install -y wget && \
    wget -O /usr/share/keyrings/iconik.asc ${REPO_BASE}/dists/noble/iconik_package_repos_pub.asc && \
    echo "deb [signed-by=/usr/share/keyrings/iconik.asc] ${REPO_BASE} ./noble main" > /etc/apt/sources.list.d/iconik.list && \
    apt-get update && \
    apt-get install -y iconik-storage-gateway && \
    apt-get purge -y --auto-remove wget && \
    rm -rf /var/lib/apt/lists/*

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
