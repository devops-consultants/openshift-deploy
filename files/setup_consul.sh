#!/usr/bin/env bash
#

yum -y install curl unzip
curl -o /tmp/consul.zip ${consul_download_url}
cd /usr/local/bin && unzip /tmp/consul.zip

getent passwd consul || useradd --system -c 'Consul User' --shell /sbin/nologin --no-create-home --user-group consul

mkdir -p /etc/consul.d/client
mkdir -p /var/consul
chown consul.consul /var/consul

cat > /etc/consul.d/client/config.json <<-EOF
{
    "bootstrap": false,
    "server": false,
    "datacenter": "${datacenter}",
    "data_dir": "/var/consul",
    "encrypt": "${encrypt_key}",
    "log_level": "INFO",
    "enable_syslog": true,
    "start_join": ["${join_server_ip"]
}
EOF

cat > cat /etc/systemd/system/consul.service <<-EOF
[Unit]
Description=consul

[Service]
Environment=
ExecStart=/usr/local/bin/consul agent -ui -config-dir /etc/consul.d/client
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=TERM
User=consul
WorkingDirectory=/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl enable consul
systemctl start consul
