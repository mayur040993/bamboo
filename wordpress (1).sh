#!/bin/bash
S_TIME=`date +%H:%M:%S`
echo "Installing wordpress"
sudo apt-get update
echo "---------- intsalling Nginx -------------------"
sudo apt-get -y install nginx
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password igdefault'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password igdefault'
echo $BAMBOO_MYSQLPASS
echo $bamboo_mysqlpass
echo $BAMBOO_mysqlpass
echo "---------- intsalling Mysql-Server -------------------"
sudo apt-get -y install mysql-server-5.6
echo "----------installing all php module------------------"
sudo apt-get -y install php5 php5-mysql php5-fpm php5-mcrypt php5-gd libssh2-php

cat>tempfile<<eof
server {
        listen   80; ## listen for ipv4; this line is default and implied
        listen   [::]:80 default ipv6only=on; ## listen for ipv6

        root /usr/share/nginx/www;
        index index.php index.html index.htm;

        # Make site accessible from http://localhost/
        server_name localhost;



location ~ \.php$ {
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini

                # With php5-cgi alone:
                #fastcgi_pass 127.0.0.1:9000;
                # With php5-fpm:
                fastcgi_pass unix:/var/run/php5-fpm.sock;
                fastcgi_index index.php;
                include fastcgi_params;
        }
}
eof
cat tempfile>/etc/nginx/sites-enabled/default
rm -f tempfile
#sudo php5enmod mcrypt
#sudo service php5-fpm restart
sed -i 's%;cgi.fix_pathinfo=1%cgi.fix_pathinfo=0/g' /etc/php5/fpm/php.ini
sed -i 's%listen = 127.0.0.1:9000; %listen = /var/run/php5-fpm.sock; %g' /etc/php5/fpm/pool.d/www.conf
sed -i 's/;listen.owner = www-data/listen.owner = www-data/g' /etc/php5/fpm/pool.d/www.conf
sed -i 's/;listen.group = www-data/listen.group = www-data/g' /etc/php5/fpm/pool.d/www.conf
sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php5/fpm/pool.d/www.conf
sudo service php5-fpm restart

sudo nginx -t
sudo service nginx restart
touch /usr/share/nginx/www/index.php
cat>>/usr/share/nginx/www/index.php<<eof
<html>
<body>
<?php
phpinfo()
?>
</body>
</html>
eof
#curl -Is locahost

sudo mysql -u root -pigdefault -e "CREATE DATABASE wordpress";
sudo mysql -u root -pigdefault -e "CREATE USER wordpressuser@localhost IDENTIFIED BY 'password';"
sudo mysql -u root -pigdefault -e "GRANT ALL PRIVILEGES ON wordpress.* TO wordpressuser@localhost;"
sudo mysql -u root -pigdefault -e "FLUSH PRIVILEGES;"
wget http://wordpress.org/latest.tar.gz
sudo tar xzvf latest.tar.gz

sudo cp wordpress/wp-config-sample.php wordpress/wp-config.php

sudo sed -i 's/database_name_here/wordpress/g' wordpress/wp-config.php
sudo sed -i 's/username_here/wordpressuser/g' wordpress/wp-config.php
sudo sed -i 's/password_here/password/g' wordpress/wp-config.php
sudo cp -r wordpress/ /usr/share/nginx/www/
chown www-data:www-data /usr/share/nginx/www/ -R

echo "please open wp"
E_TIME=`date +%H:%M:%S`
DIFF_TME=$((`date -d "$E_TIME" +%s` - `date -d "$S_TIME" +%s` |bc))
echo "total time to complete task=$DIFF_TME sec"
