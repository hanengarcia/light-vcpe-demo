#!/bin/sh

### Generate SSH key
ssh_key_private="/root/.ssh/ansible_rsa"
ssh_key_public="/root/.ssh/ansible_rsa.pub"
ssh_authorized_keys="/root/.ssh/authorized_keys"

if [ -e $ssh_key_private]
then
	echo "ssh key $ssh_key_private found, skipping"
	cat $ssh_key_public
else
	echo "ssh key $ssh_key_private not found, generating new one"
	ssh-keygen -t rsa -b 2048 -f $ssh_key_private -N ""
fi

if [ -e $ssh_authorized_keys]
then
	echo "ssh authorized keys $ssh_authorized_keys found, appending key"
	cat $ssh_key_public >> $ssh_authorized_keys
	
else
	echo "ssh authorized keys $ssh_authorized_keys not found, generating new one"
	cp $ssh_key_public $ssh_authorized_keys
	chmod 644 $ssh_authorized_keys
fi

### Get Proxy credentials
proxy_user=`hostname -s`
proxy_host='198.154.188.151'
proxy_port='8080'

### Establish SSH tunnel
ssh –f –N –T –R 0.0.0.0:${proxy_port}:localhost:22 ${proxy_user}@${proxy_host}

echo "This device is now managed via ${proxy_host}:${proxy_port}"