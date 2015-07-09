
sudo apt-get install software-properties-common

sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java8-installer
sudo apt-get install oracle-java8-set-default

wget http://www.sonatype.org/downloads/nexus-latest-bundle.tar.gz
tar zxvf nexus-latest-bundle.tar.gz
sudo mv nexus-2.11.3-01 sonatype-work /opt
sudo ln -s /opt/nexus-2.11.3-01 /opt/nexus

sudo mkdir /opt/nexus/run

adduser --system --group -c "Sonatype nexus" nexus

sudo chown -R nexus:nexus /opt/nexus-2.11.3-01
sudo chown -R nexus:nexus /opt/sonatype-work/nexus
sudo chown -R nexus:nexus /opt/nexus

sudo cp /opt/nexus/bin/nexus /opt/nexus/bin/nexus.BAK

Edit /opt/nexus/bin/nexus script changing the following variables:

NEXUS_HOME=/opt/nexus
RUN_AS_USER=nexus
PIDDIR=/opt/nexus/run


Create the file /etc/systemd/system:

[Unit]
Description=Sonatype Nexus 2.x
After=network.target

[Service]
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
ExecReload=/opt/nexus/bin/nexus restart
PIDFile=/opt/nexus/run/nexus.pid
Type=forking
User=nexus

[Install]
WantedBy=multi-user.target

systemctl enable nexus
systemctl start nexus


sudo apt-get install nginx
sudo rm /etc/nginx/sites-enabled/default

Create the file /etc/nginx/sites-available/repo.evolvedbinary.com:

server {
	listen 80;
	listen [::]:80;

	server_name repo.evolvedbinary.com;

	charset utf-8;
        access_log /var/log/nginx/repo.evolvedbinary.com_access.log;

        location / {
            proxy_pass http://localhost:8081/nexus/;
        }
}

Edit /etc/nginx/nginx.conf and set:

server_names_hash_bucket_size 64;

Then run `service nginx restart`.

apt-get install ufw
ufw enable
ufw allow ssh
ufw allow nginx


