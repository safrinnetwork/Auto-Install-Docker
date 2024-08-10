#!/bin/bash

# Update sistem
sudo apt update && sudo apt upgrade -y

# Install dependensi
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

# Tambahkan GPG key Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Tambahkan repository Docker ke sumber paket APT
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update repository paket
sudo apt update

# Install Docker
sudo apt install docker-ce docker-ce-cli containerd.io -y

# Cek status Docker
sudo systemctl status docker

# Tambahkan user ke grup docker (Opsional)
sudo usermod -aG docker ${USER}

# Verifikasi instalasi Docker
docker --version

# Jalankan container hello-world untuk menguji instalasi Docker
sudo docker run hello-world

# Set Docker agar start otomatis saat sistem dinyalakan
sudo systemctl enable docker

echo "Docker telah berhasil diinstal dan dikonfigurasi di sistem Anda."
