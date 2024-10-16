sudo yum install python3.9 nano git -y && sudo yum update -y
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install pgbackrest -y
sudo touch /etc/pgbackrest.conf
cat<<EOF | sudo tee "/etc/pgbackrest.conf"
[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
repo1-retention-diff=7
process-max=2
log-level-console=info
log-level-file=debug
# compression extrême et lente
compress-type=gz
compress-level=9

[global:archive-push]
# archivage uniquement : compression la plus rapide possible
compress-type=gz
compress-level=9
EOF
sudo chown postgres:postgres /var/lib/pgbackrest
sudo mkdir -p /etc/pgbackrest
sudo mkdir -p /etc/pgbackrest/conf.d
sudo mv /etc/pgbackrest.conf /etc/pgbackrest/
sudo chown -R postgres:postgres /etc/pgbackrest
sudo yum install postgresql-contrib -y
sudo -u postgres ssh-keygen -t rsa -N '' -f /var/lib/pgsql/.ssh/id_rsa
sudo setenforce 0
## S3
#sudo useradd -s /sbin/nologin -d /opt/minio minio
#sudo yum install -y wget
#sudo mkdir -p /opt/minio/bin/minio
#sudo wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /opt/minio/bin/minio
#sudo chmod +x /opt/minio/bin/minio
#cat<<EOF | sudo tee "/opt/minio/minio.conf"
#MINIO_VOLUMES=/opt/minio/data
#MINIO_DOMAIN=minio.local
#MINIO_OPTS="--certs-dir /opt/minio/certs --address :443 --compat"
#MINIO_ACCESS_KEY="workshop16_access_key"
#MINIO_SECRET_KEY="workshop16_secret_key" 
#EOF
#sudo chown -R minio:minio /opt/minio
#sudo mkdir ~/certs
#sudo cd ~/certs && openssl genrsa -out ca.key 2048
#sudo cd ~/certs && openssl req -new -x509 -extensions v3_ca -key ca.key -out ca.crt -days 99999 -subj "/C=BE/ST=Country/L=City/O=Organization/CN=some-really-cool-name"
#sudo cd ~/certs && openssl genrsa -out server.key 2048
#sudo cd ~/certs && openssl req -new -key server.key -out server.csr -subj "/C=BE/ST=Country/L=City/O=Organization/CN=some-really-cool-name"
#sudo cd ~/certs && openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 99999 -sha256
#sudo mkdir -p -m 755 /opt/minio/certs
#sudo cp server.crt /opt/minio/certs/public.crt
#sudo cp server.key /opt/minio/certs/private.key
#sudo chown -R minio:minio /opt/minio/certs
#sudo chmod -R 644 /opt/minio/certs/public.crt
#sudo chmod -R 644 /opt/minio/certs/private.key
#cat<<EOF | sudo tee "/etc/systemd/system/minio.service"
#[Unit]
#Description=Minio
#Documentation=https://docs.minio.io
#Wants=network-online.target
#After=network-online.target
#AssertFileIsExecutable=/opt/minio/bin/minio
#
#[Service]
#AmbientCapabilities=CAP_NET_BIND_SERVICE
#WorkingDirectory=/opt/minio
#
#User=minio
#Group=minio
#
#PermissionsStartOnly=true
#
#EnvironmentFile=-/opt/minio/minio.conf
#ExecStartPre=/bin/bash -c "[ -n \\"\${MINIO_VOLUMES}\\" ] || echo \\"Variable MINIO_VOLUMES not set in /opt/minio/minio.conf\\""
#
#ExecStart=/opt/minio/bin/minio server \$MINIO_OPTS \$MINIO_VOLUMES
#
#StandardOutput=journal
#StandardError=inherit
#
## Specifies the maximum file descriptor number that can be opened by this process
#LimitNOFILE=65536
#
## Disable timeout logic and wait until process is stopped
#TimeoutStopSec=0
#
## SIGTERM signal is used to stop Minio
#KillSignal=SIGTERM
#
#SendSIGKILL=no
#
#SuccessExitStatus=0
#
#[Install]
#WantedBy=multi-user.target
#EOF
#
#sudo systemctl enable minio
#sudo systemctl start minio
#sudo firewall-cmd --quiet --permanent --add-service=https
#sudo firewall-cmd --quiet --reload
#sudo systemctl status minio

# bucket name: q9maqbezkxk6
