#!/bin/bash

# Install Tor
apt-get update 
apt-get install --yes tor

# Create hidden service folder
mkdir -p /var/lib/tor/ssh_onion_service/
chown -R debian-tor:debian-tor /var/lib/tor/ssh_onion_service/
chmod 0700 /var/lib/tor/ssh_onion_service/

# Add settings for SSH connection
echo "" >> /etc/tor/torrc
echo "#Hidden service for SSH connections." >> /etc/tor/torrc
echo "HiddenServiceDir /var/lib/tor/ssh_onion_service/" >> /etc/tor/torrc
# Create authentication token
AUTH="$(< /dev/urandom tr -dc a-z0-9 | head -c16)"
echo "HiddenServiceAuthorizeClient stealth $AUTH" >> /etc/tor/torrc
echo "HiddenServicePort 22 127.0.0.1:51984" >> /etc/tor/torrc

service tor restart

sed -i 's/Port 22/Port 51984/g' /etc/ssh/sshd_config
service ssh restart

# Build examples of .ssh/config and /etc/tor/torrc
echo ""
CONNECTION="$(cat /var/lib/tor/ssh_onion_service/hostname)"
ONION="$(echo $CONNECTION | cut -d' ' -f1)"
echo "# Add this to your .ssh/config in client side"
echo "host hidden"
echo -e '\thostname $ONION'
echo -e '\tuser root'
echo -e '\tproxyCommand /usr/local/bin/ncat --proxy 127.0.0.1:9050 --proxy-type socks5 %h %p'
echo ""
echo "Add this line to your /etc/tor/torrc on client side."
echo "HidServAuth $CONNECTION"
echo ""
