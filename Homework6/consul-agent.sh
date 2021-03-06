#!/usr/bin/env bash
set -e

### set consul version
CONSUL_VERSION="1.4.0"

echo "Grabbing IPs..."

echo "Installing dependencies..."
apt-get -qq update &>/dev/null
apt-get -yqq install unzip dnsmasq &>/dev/null

echo "Configuring dnsmasq..."
cat << EODMCF >/etc/dnsmasq.d/10-consul
# Enable forward lookup of the 'consul' domain:
server=/consul/127.0.0.1#8600
EODMCF

systemctl restart dnsmasq

echo "Fetching Consul..."
cd /tmp
curl -sLo consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip

echo "Installing Consul..."
unzip consul.zip >/dev/null
chmod +x consul
mv consul /usr/local/bin/consul

# Setup Consul
mkdir -p /opt/consul
mkdir -p /etc/consul.d
mkdir -p /run/consul
tee /etc/consul.d/config.json > /dev/null <<EOF
{
  "advertise_addr": "$PRIVATE_IP",
  "data_dir": "/opt/consul",
  "datacenter": "consulhw",
  "encrypt": "uDBV4e+LbFW3019YKPxIrg==",
  "disable_remote_exec": true,
  "disable_update_check": true,
  "leave_on_terminate": true,
  "retry_join": ["provider=aws tag_key=consul_server tag_value=true"],
  "enable_script_checks": true,
  "server": false
}
EOF

# Create user & grant ownership of folders
useradd consul
chown -R consul:consul /opt/consul /etc/consul.d /run/consul


# Configure consul service
tee /etc/systemd/system/consul.service > /dev/null <<"EOF"
[Unit]
Description=Consul service discovery agent
Requires=network-online.target
After=network.target

[Service]
User=consul
Group=consul
PIDFile=/run/consul/consul.pid
Restart=on-failure
Environment=GOMAXPROCS=2

ExecStart=/usr/local/bin/consul agent -pid-file=/run/consul/consul.pid -config-dir=/etc/consul.d
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF

echo '{"service": {"name": "webserver", "port": 80}}' \
    | sudo tee /etc/consul.d/webserver.json

systemctl daemon-reload
systemctl enable consul.service
systemctl start consul.service

sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
HOSTNAME=$(cat /etc/hostname)
echo "<h1>Welcome to app-server $HOSTNAME</h1>" | sudo tee /var/www/html/index.html
systemctl restart apache2

#Consul service register
PUPBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
echo $PUPBLIC_IP
#consul services register -name=webserver -port=80 -address=$PUPBLIC_IP
#consul reload


