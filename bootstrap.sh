#!/bin/sh

### Generate SSH key
ssh_key_private="/root/.ssh/ansible_rsa"
ssh_key_public="/root/.ssh/ansible_rsa.pub"
ssh_authorized_keys="/root/.ssh/authorized_keys"

if [ -e $ssh_key_private ]
then
    printf "ssh key $ssh_key_private found, skipping\n"
else
    printf "ssh key $ssh_key_private not found, generating new\n"
    ssh-keygen -t rsa -b 2048 -f $ssh_key_private -N ""
fi

if [ -e $ssh_authorized_keys ]
then
    printf "ssh authorized keys $ssh_authorized_keys found, appending key\n"
    cat $ssh_key_public >> $ssh_authorized_keys
else
    printf "ssh authorized keys $ssh_authorized_keys not found, generating new one\n"
    cp $ssh_key_public $ssh_authorized_keys
    chmod 644 $ssh_authorized_keys
fi

ssh_key_private_content=`cat $ssh_key_private | base64 | tr -d '\r\n'`
ssh_key_public_content=`cat $ssh_key_public`

### Get Proxy credentials
proxy_user=`hostname -s`
proxy_host='198.154.188.151'
proxy_dest_ipv4='172.28.1.20'
proxy_dest_port='8080'


generate_post_data()
{
  cat << EOF
{
    "extra_vars":
    {
        "remote_username": "root"
        "remote_hostname": "$proxy_user",
		"remote_ipv4": "$proxy_dest_ipv4",
		"remote_port": "$proxy_dest_port",
		"remote_key_private": "$ssh_key_private_content",
		"remote_key_public": "$ssh_key_public_content"
	}
}
EOF
}

### Call Ansible Tower
curl --fail --silent --insecure -X POST \
https://tower.keepontouch.net:443/api/v2/workflow_job_templates/11/launch/ \
  -H 'authorization: Basic YWRtaW46cmVkaGF0OTk=' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d "$(generate_post_data)" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    printf "Call back home is being processed\n"
else
    printf "Call back home failed, exiting\n"
    exit 1;
fi

### Establish SSH tunnel
printf "Establishing tunnel ."

connected=false
while [ $connected = false ]
do
    # Create the SSH tunnel
    ssh -f -N -T -R ${proxy_dest_ipv4}:${proxy_dest_port}:localhost:22 ${proxy_user}@${proxy_host} \
        -i ${ssh_key_private} -o StrictHostKeyChecking=no 2>/dev/null

    if [ $? -eq 0 ]; then
        connected=true
        printf " done!\n"
    else
        sleep 10
        printf "."
    fi
done

printf "\n\nThis device is now managed via ${proxy_dest_ipv4}:${proxy_dest_port}\n\n"
