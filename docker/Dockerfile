FROM python:3.12-slim-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install glab (GitLab CLI) - fetch latest version dynamically
RUN GLAB_VERSION=$(curl -s "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases" | \
        grep -o '"tag_name":"v[^"]*"' | head -1 | cut -d'"' -f4 | tr -d 'v') && \
    curl -fsSL "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_linux_amd64.deb" \
        -o /tmp/glab.deb && dpkg -i /tmp/glab.deb && rm /tmp/glab.deb

# Install Copier
RUN pip install --no-cache-dir copier

# Add certificates to trust store (if any .pem files exist)
COPY docker/certificates/ /tmp/certs/
RUN if ls /tmp/certs/*.pem 1>/dev/null 2>&1; then \
        cp /tmp/certs/*.pem /usr/local/share/ca-certificates/ && \
        update-ca-certificates; \
    fi && rm -rf /tmp/certs

# Configure git to trust the certificates
RUN git config --global http.sslCAPath /etc/ssl/certs/

WORKDIR /workspace

# Copy template
COPY copier.yml /template/
COPY template/ /template/template/

ENTRYPOINT ["copier", "copy", "--trust", "/template"]
CMD ["/workspace"]
