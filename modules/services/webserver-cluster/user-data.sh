#!/bin/bash

sudo yum install httpd -y
sudo httpd -c "Listen 8080"
echo "<h1>Hello, World from templated file</h1>" > /var/www/html/index.html
echo "<p>DB address: ${db_address}</p>" >> /var/www/html/index.html
echo "<p>DB port: ${db_port}</p>" >> /var/www/html/index.html