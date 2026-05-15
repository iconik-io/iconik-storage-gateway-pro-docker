FROM ubuntu:24.04

LABEL maintainer="iconik Media AB <info@iconik.io>"

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.utf8

RUN apt-get update && \
    apt-get install -y poppler-utils ghostscript dcraw exiftool locales gettext-base && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ARG REPO_BASE=https://packages.iconik.io/deb/ubuntu

RUN apt-get update && apt-get install -y wget gnupg && \
    wget -O - ${REPO_BASE}/dists/noble/iconik_package_repos_pub.asc | apt-key add - && \
    echo "deb [trusted=yes] ${REPO_BASE} ./noble main" > /etc/apt/sources.list.d/iconik.list && \
    apt-get update && \
    apt-get install -y iconik-storage-gateway

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
