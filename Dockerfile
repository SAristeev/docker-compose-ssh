FROM centos:7
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

RUN yum install -y \
    openssh-server \
    openssh-clients 

RUN mkdir -p /var/run/sshd && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/ssh_config && \
    echo "PasswordAuthentication no" >> /etc/ssh/ssh_config && \
    echo "KbdInteractiveAuthentication no" >> /etc/ssh/ssh_config

COPY entrypoint.sh /bin/entrypoint.sh
RUN chmod +x /bin/entrypoint.sh