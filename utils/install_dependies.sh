#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/chabanyknikita/cosmos_scripts/main/utils/additional_commands.sh)

printCyan "1. Updating packages..." && sleep 1
sudo apt update

printCyan "2. Installing dependencies..." && sleep 1
sudo apt install -y make gcc jq curl git lz4 build-essential chrony unzip

printCyan "3. Installing go..." && sleep 1
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.19.7.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)

echo "$(go version)"