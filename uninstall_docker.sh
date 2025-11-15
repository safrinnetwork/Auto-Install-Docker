#!/bin/bash

# Script untuk uninstall Docker secara otomatis di Ubuntu/Debian
# Exit jika ada error
set -e

echo "=========================================="
echo "Script Uninstall Docker Otomatis"
echo "=========================================="
echo ""

# Cek apakah dijalankan sebagai root atau dengan sudo
if [ "$EUID" -ne 0 ]; then
    echo "Error: Script ini harus dijalankan dengan sudo"
    echo "Gunakan: sudo bash uninstall_docker.sh"
    exit 1
fi

# Konfirmasi dari user
echo "⚠ PERINGATAN: Script ini akan:"
echo "  - Stop dan disable Docker services"
echo "  - Uninstall semua Docker packages"
echo "  - Hapus SEMUA data Docker (images, containers, volumes, networks)"
echo "  - Hapus file konfigurasi Docker"
echo "  - Remove user dari docker group"
echo ""
read -p "Apakah Anda yakin ingin melanjutkan? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Uninstall dibatalkan."
    exit 0
fi

echo ""
echo "Memulai proses uninstall..."
echo ""

# Step 1: Stop dan disable Docker services
echo "[1/5] Menghentikan Docker services..."
echo ""

# Stop services
if systemctl is-active --quiet docker.service; then
    echo "  - Menghentikan docker.service..."
    systemctl stop docker.service
else
    echo "  - docker.service sudah tidak berjalan"
fi

if systemctl is-active --quiet containerd.service; then
    echo "  - Menghentikan containerd.service..."
    systemctl stop containerd.service
else
    echo "  - containerd.service sudah tidak berjalan"
fi

# Disable services
if systemctl is-enabled --quiet docker.service 2>/dev/null; then
    echo "  - Disable docker.service..."
    systemctl disable docker.service
else
    echo "  - docker.service sudah disabled"
fi

if systemctl is-enabled --quiet containerd.service 2>/dev/null; then
    echo "  - Disable containerd.service..."
    systemctl disable containerd.service
else
    echo "  - containerd.service sudah disabled"
fi

# Disable socket jika ada
if systemctl is-enabled --quiet docker.socket 2>/dev/null; then
    echo "  - Disable docker.socket..."
    systemctl disable docker.socket
fi

echo ""
echo "[1/5] ✓ Docker services berhasil dihentikan"
echo ""

# Step 2: Purge Docker packages
echo "[2/5] Menghapus Docker packages..."
echo ""

# List packages yang akan dihapus
DOCKER_PACKAGES="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras"

echo "  - Purge Docker packages..."
apt purge -y $DOCKER_PACKAGES 2>/dev/null || echo "  - Beberapa packages mungkin sudah tidak ada"

echo "  - Autoremove dependencies yang tidak terpakai..."
apt autoremove -y

echo ""
echo "[2/5] ✓ Docker packages berhasil dihapus"
echo ""

# Step 3: Hapus semua data Docker
echo "[3/5] Menghapus semua data Docker..."
echo ""

if [ -d /var/lib/docker ]; then
    echo "  - Menghapus /var/lib/docker..."
    rm -rf /var/lib/docker
else
    echo "  - /var/lib/docker sudah tidak ada"
fi

if [ -d /var/lib/containerd ]; then
    echo "  - Menghapus /var/lib/containerd..."
    rm -rf /var/lib/containerd
else
    echo "  - /var/lib/containerd sudah tidak ada"
fi

if [ -d /etc/docker ]; then
    echo "  - Menghapus /etc/docker..."
    rm -rf /etc/docker
else
    echo "  - /etc/docker sudah tidak ada"
fi

if [ -d /var/run/docker ]; then
    echo "  - Menghapus /var/run/docker..."
    rm -rf /var/run/docker
else
    echo "  - /var/run/docker sudah tidak ada"
fi

if [ -S /var/run/docker.sock ]; then
    echo "  - Menghapus /var/run/docker.sock..."
    rm -f /var/run/docker.sock
else
    echo "  - /var/run/docker.sock sudah tidak ada"
fi

echo ""
echo "[3/5] ✓ Data Docker berhasil dihapus"
echo ""

# Step 4: Hapus Docker repository
echo "[4/5] Menghapus Docker repository..."
echo ""

if [ -f /etc/apt/sources.list.d/docker.sources ]; then
    echo "  - Menghapus /etc/apt/sources.list.d/docker.sources..."
    rm -f /etc/apt/sources.list.d/docker.sources
else
    echo "  - Docker repository sudah tidak ada"
fi

if [ -f /etc/apt/keyrings/docker.asc ]; then
    echo "  - Menghapus /etc/apt/keyrings/docker.asc..."
    rm -f /etc/apt/keyrings/docker.asc
else
    echo "  - Docker GPG key sudah tidak ada"
fi

echo "  - Update package index..."
apt update -y

echo ""
echo "[4/5] ✓ Docker repository berhasil dihapus"
echo ""

# Step 5: Remove user dari docker group
echo "[5/5] Menghapus user dari docker group..."
echo ""

# Dapatkan username dari SUDO_USER jika script dijalankan dengan sudo
if [ -n "$SUDO_USER" ]; then
    USERNAME=$SUDO_USER
else
    # Jika tidak ada SUDO_USER, gunakan user yang login
    USERNAME=$(logname 2>/dev/null || echo $USER)
fi

if [ -n "$USERNAME" ] && [ "$USERNAME" != "root" ]; then
    # Cek apakah user ada di docker group
    if groups "$USERNAME" | grep -q '\bdocker\b'; then
        gpasswd -d "$USERNAME" docker
        echo "  ✓ User '$USERNAME' dihapus dari docker group"
    else
        echo "  - User '$USERNAME' tidak ada di docker group"
    fi
else
    echo "  - Tidak dapat mendeteksi user non-root"
fi

# Hapus docker group jika sudah tidak ada member
if getent group docker > /dev/null 2>&1; then
    DOCKER_GROUP_MEMBERS=$(getent group docker | cut -d: -f4)
    if [ -z "$DOCKER_GROUP_MEMBERS" ]; then
        echo "  - Menghapus docker group (sudah tidak ada member)..."
        groupdel docker 2>/dev/null || echo "  - Tidak dapat menghapus docker group"
    else
        echo "  - Docker group masih memiliki member lain, tidak dihapus"
    fi
fi

echo ""
echo "[5/5] ✓ User berhasil dihapus dari docker group"
echo ""

echo "=========================================="
echo "✓ UNINSTALL DOCKER SELESAI!"
echo "=========================================="
echo ""
echo "Docker dan semua datanya telah dihapus dari sistem."
echo ""
echo "Jika user masih login, logout dan login kembali agar"
echo "perubahan group membership berlaku."
echo ""
