#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/chabanyknikita/cosmos_scripts/main/utils/additional_commands.sh)

printCyan "1. Updating packages..." && sleep 1
sudo apt update

printCyan "2. Installing dependencies..." && sleep 1
sudo apt install -y make gcc jq curl git lz4 build-essential chrony unzip

printCyan "3. Installing go..." && sleep 1
if ! [ -x "$(command -v go)" ]; then
  source <(curl -s "https://raw.githubusercontent.com/chabanyknikita/cosmos_scripts/main/utils/install_golang.sh")
  source .bash_profile
fi

echo "$(go version)"