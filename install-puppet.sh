#!/bin/bash
apt-get install puppet augeas-tools

# stop the puppet agent, we are going to use puppet apply
systemctl disable puppet
service puppet stop 
