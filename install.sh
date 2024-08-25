#!/bin/bash

# Check 64-bit and Ubuntu
if [ "$(uname -m)" != "x86_64" ] || ! grep -q 'Ubuntu' /etc/os-release; then
    echo "Script ini hanya bisa dijalankan pada Linux Ubuntu 64-bit."
    exit 1
fi

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo "Script ini harus dijalankan sebagai root."
    exit 1
fi

# Update package index
apt-get update
apt-get install -y ca-certificates curl

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update

# Install Docker
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add Docker group if it doesn't exist
if ! getent group docker > /dev/null; then
    groupadd docker
fi

# Add current user to Docker group
usermod -aG docker $USER

# Inform the user to log out and log back in for group changes to take effect
echo "Untuk menggunakan Docker, silakan log out dan log in kembali."

# Enable auto start Docker
systemctl enable docker.service
systemctl enable containerd.service

# Close message
echo "Penginstalan Docker sudah selesai."
