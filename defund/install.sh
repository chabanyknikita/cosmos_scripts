#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/chabanyknikita/cosmos_scripts/main/utils/additional_commands.sh)

printLogo

CHAIN_ID="orbit-alpha-1"
CHAIN_DENOM="ufetf"
BINARY_NAME="defundd"
BINARY_VERSION_TAG="v0.2.6"

read -r -p "Enter node moniker: " NODE_MONIKER

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/chabanyknikita/cosmos_scripts/main/utils/install_dependies.sh)

printCyan "4. Building binaries..." && sleep 1

cd $HOME
rm -rf defund
git clone https://github.com/defund-labs/defund.git
cd defund
git checkout v0.2.6
make install

defundd config chain-id orbit-alpha-1
defundd init "$NODE_MONIKER" --chain-id orbit-alpha-1

curl -Ls https://rpc.defund-testnet.mirror-reflection.com/genesis | jq -r .result.genesis > $HOME/.defund/config/genesis.json
curl -s https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/defund-testnet/addrbook.json > $HOME/.defund/config/addrbook.json

SEEDS="1f3d588a560c1560d3862c364006fc984e6b51a9@rpc.defund-testnet.mirror-reflection.com:26656,3f472746f46493309650e5a033076689996c8881@defund-testnet.rpc.kjnodes.com:40659"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.defund/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.defund/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.defund/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.defund/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.defund/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ufetf"|g' $HOME/.defund/config/app.toml
defundd tendermint unsafe-reset-all --home $HOME/.defund --keep-addr-book

printCyan "5. Changing port if you have more one node or enter 0 for default port..." && sleep 1

source <(curl -s https://raw.githubusercontent.com/chabanyknikita/cosmos_scripts/main/utils/change_port.sh) .defund

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/defundd.service > /dev/null << EOF
[Unit]
Description=defund-testnet node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which defundd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF


curl -L https://snapshots-cosmos.mirror-reflection.com/cosmos-testnet/defund-testnet/orbit-alpha-1_latest.tar | tar -xf - -C $HOME/.defund/data
sudo systemctl daemon-reload
sudo systemctl enable defundd
sudo systemctl start defundd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"


array_rpc=(26 27 28 29 30 31 32 33 34 35 36)
array_api=(13 14 15 16 17 18 19 20 21 22 23)
array_gRPC_web=(90 91 92 93 94 95 96 97 98 100)
array_laddr=(60 61 62 63 64 65 66 67 68 69 70)


read -r -p "Choose port from 0 to 10:" PORT

sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${array_rpc[$PORT]}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${array_rpc[$PORT]}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${array_laddr[$PORT]}60\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${array_rpc[$PORT]}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${array_rpc[$PORT]}660\"%" $HOME/.defund/config/config.toml && sed -i.bak -e "s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${array_gRPC_web[$PORT]}90\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${array_gRPC_web[$PORT]}91\"%; s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${array_api[$PORT]}17\"%" $HOME/.defund/config/app.toml && sed -i.bak -e "s%^node = \"tcp://localhost:26657\"%node = \"tcp://localhost:{array_rpc[$PORT]}657\"%" $HOME/.defund/config/client.toml 
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${array_rpc[$PORT]}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${array_rpc[$PORT]}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${array_laddr[$PORT]}60\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${array_rpc[$PORT]}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${array_rpc[$PORT]}660\"%" $HOME/.defund/config/config.toml && sed -i.bak -e "s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${array_gRPC_web[$PORT]}90\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${array_gRPC_web[$PORT]}91\"%; s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${array_api[$PORT]}17\"%" $HOME/.defund/config/app.toml && sed -i.bak -e "s%^node = \"tcp://localhost:26657\"%node = \"tcp://localhost:{array_rpc[$PORT]}657\"%" $HOME/.defund/config/client.toml 
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${array_rpc[$PORT]}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${array_rpc[$PORT]}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${array_laddr[$PORT]}60\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${array_rpc[$PORT]}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${array_rpc[$PORT]}660\"%" $HOME/.defund/config/config.toml && sed -i.bak -e "s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${array_gRPC_web[$PORT]}90\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${array_gRPC_web[$PORT]}91\"%; s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${array_api[$PORT]}17\"%" $HOME/.defund/config/app.toml && sed -i.bak -e "s%^node = \"tcp://localhost:26657\"%node = \"tcp://localhost:{array_rpc[$PORT]}657\"%" $HOME/.defund/config/client.toml 
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${array_rpc[$PORT]}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${array_rpc[$PORT]}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${array_laddr[$PORT]}60\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${array_rpc[$PORT]}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${array_rpc[$PORT]}660\"%" $HOME/.defund/config/config.toml && sed -i.bak -e "s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${array_gRPC_web[$PORT]}90\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${array_gRPC_web[$PORT]}91\"%; s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${array_api[$PORT]}17\"%" $HOME/.defund/config/app.toml && sed -i.bak -e "s%^node = \"tcp://localhost:26657\"%node = \"tcp://localhost:{array_rpc[$PORT]}657\"%" $HOME/.defund/config/client.toml 