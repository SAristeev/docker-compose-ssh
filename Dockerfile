FROM debian:12.10-slim

RUN apt-get update && \
    apt-get install -y \
    openssh-server \
    openssh-client \
    gosu

RUN mkdir -p /var/run/sshd && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/ssh_config && \
    echo "PasswordAuthentication no" >> /etc/ssh/ssh_config && \
    echo "KbdInteractiveAuthentication no" >> /etc/ssh/ssh_config

COPY entrypoint.sh /bin/entrypoint.sh
RUN chmod +x /bin/entrypoint.sh