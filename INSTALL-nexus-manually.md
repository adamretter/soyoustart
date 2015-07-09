
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


*** Proxying
Edit the file /opt/nexus/conf/nexus.properties and set:

nexus-webapp-context-path=/


Also see http://books.sonatype.com/nexus-book/reference/install-sect-proxy.html

sudo apt-get install nginx
sudo rm /etc/nginx/sites-enabled/default

Create the file /etc/nginx/sites-available/repo.evolvedbinary.com:

server {
        listen 80;
        listen [::]:80;

        server_name repo.evolvedbinary.com;

        charset utf-8;
        access_log /var/log/nginx/repo.evolvedbinary.com_access.log;

	client_max_body_size 99M;

        location / {
            proxy_pass http://localhost:8081;
            proxy_send_timeout 120;
            proxy_read_timeout 300;
            proxy_buffering off;
            keepalive_timeout 5;
            tcp_nodelay on;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
}


Edit /etc/nginx/nginx.conf and set:

server_names_hash_bucket_size 64;

Then run `service nginx restart`.

apt-get install ufw
ufw enable
ufw allow ssh
ufw allow nginx


