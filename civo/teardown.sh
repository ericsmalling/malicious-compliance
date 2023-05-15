#!/bin/bash

echo "💀 Terminating instance"
civo instance remove -y malcomp | grep -v "api.github.com"

echo "💀 Removing firewall"
civo firewall remove -y malcomp-fw | grep -v "api.github.com"

echo "💀 Removing temporary ssh key"
civo sshkey remove -y malcomp-key | grep -v "api.github.com"
rm ./malcomp-key*