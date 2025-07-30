#!/bin/bash
set -e

HOSTNAME=$(hostname -f)
USERNAME=$1
SIBLINGS=$2

echo HOSTNAME: $HOSTNAME
echo USERNAME: $USERNAME
echo SIBLINGS: $SIBLINGS

##############
# Create user
useradd -m -s /bin/bash $USERNAME


##############
# SSH setup
gosu $USERNAME mkdir -p /home/$USERNAME/.ssh

# Create public key and copy to volume
gosu $USERNAME ssh-keygen -t rsa -N "" -f /home/$USERNAME/.ssh/id_rsa
cp "/home/$USERNAME/.ssh/id_rsa.pub" "/ssh-keys/$HOSTNAME.pub"


IFS=',' read -ra siblings_array <<< "$SIBLINGS"
for sibling in "${siblings_array[@]}"; do
    echo "Add $sibling to ssh config for $USERNAME"
    echo "Host $sibling" >> /home/$USERNAME/.ssh/config
    echo "  Hostname $sibling" >> /home/$USERNAME/.ssh/config
    echo "  User $USERNAME" >> /home/$USERNAME/.ssh/config
    echo "  Port 22" >> /home/$USERNAME/.ssh/config
    echo "  IdentityFile /home/$USERNAME/.ssh/id_rsa" >> /home/$USERNAME/.ssh/config
    echo "  IdentitiesOnly yes" >> /home/$USERNAME/.ssh/config
    
    # Not secure - Man-in-the-Middle (MITM) attack is possible
    echo "  StrictHostKeyChecking no" >> /home/$USERNAME/.ssh/config
    echo "" >> /home/$USERNAME/.ssh/config
done

# Waiting other nodes
while [ $(ls /ssh-keys | wc -l) -lt $(echo $SIBLINGS | tr ',' ' ' | wc -w) ]; do
    echo "Waiting other nodes..."
    sleep 2
done


# Copy public keys from volume
for sibling in "${siblings_array[@]}"; do
    echo "Copy $sibling's public keys"
    cat /ssh-keys/$sibling.pub >> /home/$USERNAME/.ssh/authorized_keys
done

chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh/*
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/*

# Launch SSH-daemon
exec /usr/sbin/sshd -D