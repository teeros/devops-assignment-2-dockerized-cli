# Lightweight Linux base image
FROM alpine:3.19

# Install only the packages required by the diagnostic scripts:
#   bash       - script interpreter (Alpine's default shell is ash)
#   coreutils  - df, free-equivalents, date, uname, etc.
#   procps     - free, uptime
#   iproute2   - not used directly here but kept minimal; ping/getent below
#   iputils    - ping
#   bind-tools - getent-like host resolution helpers (host/dig)
RUN apk add --no-cache \
        bash \
        coreutils \
        procps \
        iproute2 \
        iputils \
        bind-tools

# Copy the application into the image
COPY app/ /app/

# Set executable permissions
RUN chmod +x /app/diagnostic.sh /app/health-check.sh

WORKDIR /app

# Basic container health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD /app/health-check.sh

ENTRYPOINT ["/app/diagnostic.sh"]
CMD ["help"]
