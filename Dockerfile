# Build stage
FROM debian:stable-slim AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
        unzip \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Second layer: ET base files
WORKDIR /legacy/server
RUN mkdir -p etmain/mapscripts && \
    mkdir -p /legacy/server/etmain && \
    curl -SL "https://cdn.splashdamage.com/downloads/games/wet/et260b.x86_full.zip" -o /tmp/et_full.zip && \
    cd /tmp && \
    unzip -q et_full.zip && \
    chmod +x et260b.x86_keygen_V03.run && \
    sh et260b.x86_keygen_V03.run --tar xf && \
    cp /tmp/etmain/pak*.pk3 /legacy/server/etmain/ && \
    rm -rf /tmp/et_full.zip /tmp/et260b.x86_keygen_V03.run /tmp/etmain

# Config files
# RUN mkdir -p /legacy/homepath && \
#     git clone --depth 1 --single-branch "https://github.com/kraszken/legacy-config-pub.git" /tmp/legacy-config && \
#     cp -rT /tmp/legacy-config /legacy/server/etmain && \
#     rm -rf /tmp/legacy-config


# ET Legacy files
ARG STATIC_URL_AMD64
ARG STATIC_URL_ARM64
ARG TARGETARCH

# Download and extract the correct version based on architecture
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        echo "Downloading ARM64 version..." && \
        curl -SL "${STATIC_URL_ARM64}" | tar xz --strip-components=1; \
    else \
        echo "Downloading AMD64 version..." && \
        curl -SL "${STATIC_URL_AMD64}" | tar xz --strip-components=1; \
    fi && \
    mv etlded.$(arch) etlded && \
    mv etlded_bot.$(arch).sh etlded_bot.sh

COPY --chmod=755 entrypoint.sh ./start
COPY --chmod=755 autorestart.sh ./autorestart

# Final stage
FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        git \
        qstat \
        curl \
        ca-certificates \
        parallel \
        nano \
    && if [ "$(arch)" = "aarch64" ]; then \
        wget -q https://github.com/icedream/icecon/releases/download/v1.0.0/icecon_linux_arm -O /bin/icecon; \
    else \
        wget -q https://github.com/icedream/icecon/releases/download/v1.0.0/icecon_linux_amd64 -O /bin/icecon; \
    fi \
    && chmod +x /bin/icecon \
    && mkdir -p /legacy/server/legacy \
    && wget -q https://raw.githubusercontent.com/LuaDist/dkjson/master/dkjson.lua -O /legacy/server/legacy/dkjson.lua \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -Ms /bin/bash legacy

# Copy files from builder
COPY --from=builder --chown=legacy:legacy /legacy /legacy/

# Configure volumes and working directory
VOLUME ["/legacy/homepath", "/legacy/server/etmain"]
WORKDIR /legacy/server

# Expose port and set user
EXPOSE 27960/UDP
USER legacy

# Set entrypoint
ENTRYPOINT ["./start"]