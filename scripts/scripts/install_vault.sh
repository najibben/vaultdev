#!/usr/bin/env bash
set -x

IFACE=`route -n | awk '$1 == "192.168.2.0" {print $8}'`
CIDR=`ip addr show ${IFACE} | awk '$2 ~ "192.168.2" {print $2}'`
IP=${CIDR%%/24}

if [ -d /vagrant ]; then
  LOG="/vagrant/logs/vault_${HOSTNAME}.log"
else
  LOG="consul.log"
fi


which /usr/local/bin/vault &>/dev/null || {
    pushd /usr/local/bin
    [ -f vault_0.10.3_linux_amd64.zip ] || {
        sudo wget https://releases.hashicorp.com/vault/0.10.3/vault_0.10.3_linux_amd64.zip
    }
    sudo unzip vault_0.10.3_linux_amd64.zip
    sudo chmod +x vault
    popd
}

#lets kill past instance
sudo killall vault &>/dev/null

#lets delete old consul storage
sudo consul kv delete -recurse vault


#start vault
sudo /usr/local/bin/vault server  -dev -dev-listen-address=${IP}:8200 -config=/usr/local/bootstrap/conf/vault.hcl &> ${LOG} &
echo vault started
sleep 3

#test vault kv works
sudo VAULT_ADDR="http://${IP}:8200" vault kv put secret/hello value=world
sudo VAULT_ADDR="http://${IP}:8200" vault kv get secret/hello

