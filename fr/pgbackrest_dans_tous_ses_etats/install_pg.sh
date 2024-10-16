sudo yum install python3.9 nano git -y && sudo yum update -y
sudo dnf install epel-release -y
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql16-server 
sudo /usr/pgsql-16/bin/postgresql-16-setup initdb
sudo systemctl enable postgresql-16
sudo systemctl start postgresql-16
sudo yum update -y
sudo yum install postgresql-contrib -y
sudo -iu postgres ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y >/dev/null 2>&1
sudo setenforce 0
sudo -u postgres ssh-keygen -t rsa -N '' -f /var/lib/pgsql/.ssh/id_rsa
