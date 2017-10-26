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
	echo "ssh key $ssh_key_private not found, generating new"
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

### Call Ansible Tower
curl --silent --insecure -X POST \
  https://tower.keepontouch.net:443/api/v2/job_templates/9/launch/ \
  -H 'authorization: Basic YWRtaW46cmVkaGF0OTk=' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'postman-token: 7aafe9c1-f3fa-60cb-8787-6567f0d19d3c' \
  -d "{
  \"extra_vars\": 
  {
    \"remote_hostname\": \"${proxy_user}\",
    \"remote_key_public\": \"${ssh_key_public}\"
   }
}"


### Establish SSH tunnel
echo "\n\n\nssh –f –N –T –R 172.28.1.20:${proxy_port}:localhost:22 ${proxy_user}@${proxy_host}\n\n\n"

echo -n "Establishing tunnel ."

connected=false
while [ $connected = false ]
do
	# Create the SSH tunnel 
	ssh -f -N -T -R 172.28.1.20:${proxy_port}:localhost:22 ${proxy_user}@${proxy_host}
	
	if [ $? -eq 0 ]; then
		connected=true
		echo " done!"
	else
		sleep 10
		echo -n "."
	fi
done

echo "This device is now managed via ${proxy_host}:${proxy_port}"
