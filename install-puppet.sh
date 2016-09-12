#!/bin/bash
apt-get install puppet augeas-tools

# stop the puppet agent, we are going to use puppet apply
update-rc.d puppet disable
service puppet stop 
