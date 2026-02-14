```sh
# alpine base lightweight
FROM debian:bullseye-slim

# Install dependencies & packages
RUN apt-get update && apt-get install -y curl dpkg git bash \
    && rm -rf /var/lib/apt/lists/*

# install Cloudflared
RUN curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
    && dpkg -i cloudflared.deb

# CMD + variable secret
CMD ["cloudflared", "tunnel", "--no-autoupdate", "run", "--token", "${CLOUDFLARED_TOKEN}"]
