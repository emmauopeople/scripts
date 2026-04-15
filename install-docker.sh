#!/usr/bin/env bash

set -e

echo "=========================================="
echo "  Universal Docker + Docker Compose Setup"
echo "=========================================="

# Detect OS and distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

echo "Detected OS: $OS $VER"
echo ""

install_docker_debian() {
    echo "Installing Docker on Debian/Ubuntu..."

    sudo apt update -y
    sudo apt install -y ca-certificates curl gnupg lsb-release

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/$OS \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Docker installed successfully."
}

install_docker_rhel() {
    echo "Installing Docker on RHEL/CentOS/Rocky/AlmaLinux..."

    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Docker installed successfully."
}

install_docker_fedora() {
    echo "Installing Docker on Fedora..."

    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Docker installed successfully."
}

install_docker_amazon() {
    echo "Installing Docker on Amazon Linux..."

    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo systemctl enable docker
    sudo systemctl start docker

    echo "Docker installed successfully."
}

install_docker_arch() {
    echo "Installing Docker on Arch Linux..."

    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm docker docker-compose

    echo "Docker installed successfully."
}

install_docker_suse() {
    echo "Installing Docker on openSUSE..."

    sudo zypper refresh
    sudo zypper install -y docker docker-compose

    echo "Docker installed successfully."
}

# OS selection logic
case "$OS" in
    ubuntu|debian)
        install_docker_debian
        ;;
    centos|rhel|rocky|almalinux)
        install_docker_rhel
        ;;
    fedora)
        install_docker_fedora
        ;;
    amzn)
        install_docker_amazon
        ;;
    arch)
        install_docker_arch
        ;;
    opensuse*|sles)
        install_docker_suse
        ;;
    *)
        echo "Unsupported or unknown Linux distribution: $OS"
        echo "Please install Docker manually from https://docs.docker.com/engine/install/"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "  Enabling Docker service"
echo "=========================================="

sudo systemctl enable docker
sudo systemctl start docker

echo ""
echo "=========================================="
echo "  Adding current user to docker group"
echo "=========================================="

sudo usermod -aG docker $USER

echo ""
echo "=========================================="
echo "  Docker Installation Complete!"
echo "  Log out and log back in to use Docker"
echo "=========================================="
