#!/bin/bash
cd /tmp
apt update

apt install -y jq pv bat python3-pipwget apt-transport-https gnupg lsb-release
mkdir -p ~/.local/bin
ln -s /usr/bin/batcat ~/.local/bin/bat

pip3 install jtbl

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt update
sudo apt install -y trivy

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

cd ~ubuntu
wget https://static.snyk.io/cli/latest/snyk-linux -O /usr/local/bin/snyk
chmod +x /usr/local/bin/snyk


git clone https://github.com/ericsmalling/malicious-compliance
chown -R ubuntu:ubuntu malicious-compliance
cd malicious-compliance
git checkout snyk
