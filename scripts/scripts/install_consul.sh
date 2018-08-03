#!/usr/bin/env bash
set -x


IFACE=`route -n | awk '$1 == "192.168.2.0" {print $8;exit}'`
CIDR=`ip addr show ${IFACE} | awk '$2 ~ "192.168.2" {print $2}'`
IP=${CIDR%%/24}

if [ -d /vagrant ]; then
  LOG="/vagrant/logs/consul_${HOSTNAME}.log"
else
  LOG="consul.log"
fi


PKG="wget unzip"
which ${PKG} &>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y ${PKG}
}

# check consul binary
[ -f /usr/local/bin/consul ] &>/dev/null || {
    pushd /usr/local/bin
    [ -f consul_1.2.1_linux_amd64.zip ] || {
        sudo wget https://releases.hashicorp.com/consul/1.2.1/consul_1.2.1_linux_amd64.zip
    }
    sudo unzip consul_1.2.1_linux_amd64.zip
    sudo chmod +x consul
    popd
}

# check consul-template binary
[ -f /usr/local/bin/consul-template ] &>/dev/null || {
    pushd /usr/local/bin
    [ -f consul-template_0.19.5_linux_amd64.zip ] || {
        sudo wget https://releases.hashicorp.com/consul-template/0.19.5/consul-template_0.19.5_linux_amd64.zip
    }
    sudo unzip consul-template_0.19.5_linux_amd64.zip
    sudo chmod +x consul-template
    popd
}

AGENT_CONFIG="-config-dir=/etc/consul.d -enable-script-checks=true"
sudo mkdir -p /etc/consul.d

/usr/local/bin/consul members 2>/dev/null || {
  sudo /usr/local/bin/consul agent -server -ui -client=0.0.0.0 -bind=${IP} ${AGENT_CONFIG} -data-dir=/usr/local/consul -bootstrap-expect=1 >${LOG} &
  sleep 5
}


echo consul started
