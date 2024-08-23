# Dockerfile
FROM ubuntu:latest

# Install necessary packages
RUN apt-get update && \
    apt-get install -y wget unzip

# Copy and set up scripts
COPY main-script.sh /usr/local/bin/main-script.sh
RUN chmod +x /usr/local/bin/main-script.sh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/main-script.sh"]
