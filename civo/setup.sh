#!/bin/bash
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DISK_IMAGE_DEFAULT="ubuntu-jammy"
I_NAME_DEFAULT="smalls"
SETUP_SCRIPT_DEFAULT="${CWD}/vm-init.sh"

if [ "$1" == "default" ]; then
  echo "🔥 Using defaults"
  I_NAME=$I_NAME_DEFAULT
  DISK_IMAGE=$DISK_IMAGE_DEFAULT
  SETUP_SCRIPT=$SETUP_SCRIPT_DEFAULT
else
  read -p "💻 Enter a name for your instance [$I_NAME_DEFAULT]: " I_NAME
  I_NAME=${I_NAME:-$I_NAME_DEFAULT}

  read -p "📜 Enter path to a setup script (use n for none) [$SETUP_SCRIPT_DEFAULT]: " SETUP_SCRIPT
  SETUP_SCRIPT=${SETUP_SCRIPT:-$SETUP_SCRIPT_DEFAULT}
  if [ "$SETUP_SCRIPT" == "n" ]; then
    SETUP_SCRIPT=""
  else
    SCRIPT_CMD="--script ${SETUP_SCRIPT}"
  fi

  read -p "🐕 Enter your SNYK_TOKEN [${SNYK_TOKEN//?/*}] (use n for none): " NEW_SNYK_TOKEN
  if [ "$NEW_SNYK_TOKEN" == "n" ]; then
    NEW_SNYK_TOKEN=""
    SNYK_TOKEN=""
  fi
  if [ -z "$NEW_SNYK_TOKEN" ]; then
    if [ -z "$SNYK_TOKEN" ]; then
      echo "No SNYK_TOKEN entered, set one in the instance in order to scan with Snyk Container"
    fi
  else
    SNYK_TOKEN=$NEW_SNYK_TOKEN
  fi

  read -p "🖼 Enter a disk image [$DISK_IMAGE_DEFAULT]: " DISK_IMAGE
  DISK_IMAGE=${DISK_IMAGE:-$DISK_IMAGE_DEFAULT}
fi

echo "▶️ Beginning provisioning with the following parameters:"
echo "   ▪ Instance name: $I_NAME"
echo "   ▪ Disk image: $DISK_IMAGE"
echo "   ▪ Setup script: $SETUP_SCRIPT"
echo "   ▪ SNYK_TOKEN: ${SNYK_TOKEN//?/*}"
sleep 5

echo "🔑 Creating temporary ssh key"
ssh-keygen -f ./$I_NAME-key -b 2048 -q -N ""
echo -n "   ▪ "; civo sshkey create $I_NAME-key -k ./$I_NAME-key.pub | grep -v "api.github.com"

LOCAL_IP="$(curl -s ifconfig.co/)/32"
echo "🔥 Creating firewall to limit ingress from only $LOCAL_IP"
echo -n "   ▪ "; civo firewall create $I_NAME-fw --create-rules=false | grep -v "api.github.com"
echo -n "   ▪ "; civo firewall rule create $I_NAME-fw -s=1 -e=65535 -p TCP -c $LOCAL_IP | grep -v "api.github.com"
echo -n "   ▪ "; civo firewall rule create $I_NAME-fw -s=1 -e=65535 -p TCP -d egress | grep -v "api.github.com"

echo "🔨 Provisioning instance"
echo -n "  ▪ "; civo instance create -s $I_NAME -u ubuntu -i g3.medium -k $I_NAME-key --diskimage=$DISK_IMAGE $SCRIPT_CMD -w -p=create | grep -v "api.github.com"

PUBLIC_IP="$(civo instance show $I_NAME -o custom -f public_ip | tail -1)"

echo "⌚️ waiting for instance to be ready"
# wait for ssh to be ready
while ! ssh -o StrictHostKeyChecking=no -i ./$I_NAME-key ubuntu@$PUBLIC_IP "echo 'ready'"; do
  echo -n "."
  sleep 1
done

if [ ! -z "SNYK_TOKEN" ]; then
  ssh ubuntu@$PUBLIC_IP -o StrictHostKeyChecking=no -i ./$I_NAME-key "echo export SNYK_TOKEN=${SNYK_TOKEN} >> ~/.bashrc"
fi

echo "🏁 Done!"
echo "📝 Don't forget to run ./teardown.sh when you're done to clean up"
echo
echo "💻 Shell access via: ssh ubuntu@$PUBLIC_IP -i ./$I_NAME-key"
echo