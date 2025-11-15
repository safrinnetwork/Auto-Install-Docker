#!/bin/bash

# Script untuk instalasi Docker secara otomatis di Ubuntu/Debian
# Exit jika ada error
set -e

echo "=========================================="
echo "Script Instalasi Docker Otomatis"
echo "=========================================="
echo ""

# Cek apakah dijalankan sebagai root atau dengan sudo
if [ "$EUID" -ne 0 ]; then
    echo "Error: Script ini harus dijalankan dengan sudo"
    echo "Gunakan: sudo bash install_docker.sh"
    exit 1
fi

# Step 1: Set up Docker's apt repository
echo "[1/3] Menyiapkan Docker apt repository..."
echo ""

echo "  - Update package index..."
apt update -y

echo "  - Install dependencies..."
apt install -y ca-certificates curl

echo "  - Membuat direktori keyrings..."
install -m 0755 -d /etc/apt/keyrings

echo "  - Download Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "  - Menambahkan Docker repository..."
tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

echo "  - Update package index dengan repository baru..."
apt update -y

echo ""
echo "[1/3] ✓ Docker repository berhasil ditambahkan"
echo ""

# Step 2: Install Docker packages
echo "[2/3] Menginstall Docker packages..."
echo ""

apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ""
echo "[2/3] ✓ Docker packages berhasil diinstall"
echo ""

# Step 3: Enable Docker services
echo "[3/3] Mengaktifkan Docker services saat startup..."
echo ""

systemctl enable docker.service
systemctl enable containerd.service

echo ""
echo "[3/3] ✓ Docker services berhasil diaktifkan"
echo ""

# Bonus: Add user to docker group
echo "[BONUS] Menambahkan user ke docker group..."
echo ""

# Dapatkan username dari SUDO_USER jika script dijalankan dengan sudo
if [ -n "$SUDO_USER" ]; then
    USERNAME=$SUDO_USER
else
    # Jika tidak ada SUDO_USER, gunakan user yang login
    USERNAME=$(logname 2>/dev/null || echo $USER)
fi

if [ -n "$USERNAME" ] && [ "$USERNAME" != "root" ]; then
    usermod -aG docker "$USERNAME"
    echo "  ✓ User '$USERNAME' ditambahkan ke docker group"
    echo "  ⚠ PENTING: Logout dan login kembali agar perubahan berlaku"
    echo "  Setelah itu Anda bisa menjalankan docker tanpa sudo"
else
    echo "  ⚠ Tidak dapat mendeteksi user non-root, skip menambahkan ke docker group"
fi

echo ""
echo "=========================================="
echo "✓ INSTALASI DOCKER SELESAI!"
echo "=========================================="
echo ""
echo "Informasi versi:"
docker --version
docker compose version
echo ""
echo "Status Docker service:"
systemctl status docker --no-pager -l | head -n 5
echo ""
echo "Untuk mulai menggunakan Docker:"
echo "  1. Logout dan login kembali (agar docker group aktif)"
echo "  2. Test dengan: docker run hello-world"
echo ""
