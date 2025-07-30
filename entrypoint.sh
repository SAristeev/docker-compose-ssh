#!/bin/bash
set -e

HOSTNAME=$(hostname -f)
SIBLINGS=$1

echo HOSTNAME: $HOSTNAME
echo SIBLINGS: $SIBLINGS

##############
# SSH setup
mkdir -p /root/.ssh

# Create public key and copy to volume
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
cp /root/.ssh/id_rsa.pub "/ssh-keys/$HOSTNAME.pub"


IFS=',' read -ra siblings_array <<< "$SIBLINGS"
for sibling in "${siblings_array[@]}"; do
    echo "Add $sibling to ssh config for $USERNAME"
    echo "Host $sibling" >> /root/.ssh/config
    echo "  Hostname $sibling" >> /root/.ssh/config
    echo "  User root" >> /root/.ssh/config
    echo "  Port 22" >> /root/.ssh/config
    echo "  IdentityFile /root/.ssh/id_rsa" >> /root/.ssh/config
    echo "  IdentitiesOnly yes" >> /root/.ssh/config
    
    # Not secure - Man-in-the-Middle (MITM) attack is possible
    echo "  StrictHostKeyChecking no" >> /root/.ssh/config
    echo "" >> /root/.ssh/config
done

sleep 2
# Waiting other nodes
while [ $(ls /ssh-keys | wc -l) -lt $(echo $SIBLINGS | tr ',' ' ' | wc -w) ]; do
    echo "Waiting other nodes..."
    sleep 2
done

# Copy public keys from volume
for sibling in "${siblings_array[@]}"; do
    echo "Copy $sibling's public keys"
    cat /ssh-keys/$sibling.pub >> /root/.ssh/authorized_keys
done

chmod 700 /root/.ssh
chmod 600 /root/.ssh/*

# Launch SSH-daemon
exec /usr/sbin/sshd -D