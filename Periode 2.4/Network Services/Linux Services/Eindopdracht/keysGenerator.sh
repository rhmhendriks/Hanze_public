#!/bin/bash
name=$1

#Generate Keys
salt-key --gen-keys=$name --gen-keys-dir="/tmp/keys/$name"

#Accept Keys
cp /tmp/keys/$name/$name.pub /etc/salt/pki/master/minions/$name

#print to screen
cat /tmp/keys/$name/$name.pub
echo ""
cat /tmp/keys/$name/$name.pem