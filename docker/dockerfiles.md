### Dockerfile alpine
    # Use Alpine as the base image
    FROM alpine:latest
    # Install a package (e.g., curl)
    RUN apk add --no-cache curl
    # Set default command
    CMD ["sh"]
