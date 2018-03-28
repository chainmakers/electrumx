#!/bin/bash
COIN=$1
RPCUSER=$2
RPCPASSWORD=$3
RPCPORTASSET=$4

let "RPCPORTELECTRUM = 3 + $RPCPORTASSET"

echo $RPCPORTELECTRUM
HOSTIP=$5
TCPPORT=$6

LCASECOIN=$(echo "$COIN" | awk '{print tolower($0)}')
LCASECOIN=$(echo "${LCASECOIN^}")
echo $LCASECOIN

sudo add-apt-repository ppa:jonathonf/python-3.6
sudo apt-get update
sudo apt-get install python3-setuptools python3.6 python3.6-dev libleveldb-dev --yes

sudo apt-get install python3-pip --yes
sudo pip3 install multidict

git clone https://github.com/chainmakers/electrumx -b kmdassets
cd electrumx
git pull

echo -e "\n\nclass $LCASECOIN(KomodoMixin, EquihashMixin, Coin):" >> lib/coins.py
echo -e "    NAME = "$LCASECOIN"" >> lib/coins.py
echo -e "    SHORTNAME = "$COIN"" >> lib/coins.py
echo -e "    NET = "mainnet"" >> lib/coins.py
echo -e "    TX_COUNT = 100" >> lib/coins.py
echo -e "    TX_COUNT_HEIGHT = 50" >> lib/coins.py
echo -e "    TX_PER_BLOCK = 2" >> lib/coins.py
echo -e "    RPC_PORT = $RPCPORTASSET" >> lib/coins.py
echo -e "    REORG_LIMIT = 800" >> lib/coins.py
echo -e "    PEERS = []" >> lib/coins.py

sudo python3.6 setup.py install

sudo cp contrib/systemd/electrumx.service /etc/systemd/system/electrumx_$COIN.service

sudo sed -i -e 's/'"Description=Electrumx"'/'"Description=Electrumx_$COIN"'/g' /etc/systemd/system/electrumx_$COIN.service
sudo sed -i -e 's|'"EnvironmentFile=/etc/electrumx.conf"'|'"EnvironmentFile=/etc/electrumx_$COIN.conf"'|g' /etc/systemd/system/electrumx_$COIN.service
sudo sed -i -e 's/'"User=electrumx"'/'"User=$USER"'/g' /etc/systemd/system/electrumx_$COIN.service

mkdir ~/electrumdb_$COIN

sudo touch /etc/electrumx_$COIN.conf

echo "COIN = $LCASECOIN" | sudo tee --append /etc/electrumx_$COIN.conf
echo "DB_DIRECTORY = /home/$USER/electrumdb_$COIN" | sudo tee --append /etc/electrumx_$COIN.conf
echo "DAEMON_URL = http://$RPCUSER:$RPCPASSWORD@127.0.0.1:$RPCPORTASSET/" | sudo tee --append /etc/electrumx_$COIN.conf
echo "RPC_HOST = 127.0.0.1" | sudo tee --append /etc/electrumx_$COIN.conf
echo "RPC_PORT = $RPCPORTELECTRUM" | sudo tee --append /etc/electrumx_$COIN.conf
echo "HOST = 127.0.0.1, $HOSTIP" | sudo tee --append /etc/electrumx_$COIN.conf
echo "TCP_PORT = $TCPPORT" | sudo tee --append /etc/electrumx_$COIN.conf
echo "EVENT_LOOP_POLICY = uvloop" | sudo tee --append /etc/electrumx_$COIN.conf
echo "PEER_DISCOVERY = self" | sudo tee --append /etc/electrumx_$COIN.conf

