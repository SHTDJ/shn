#!/bin/bash

sudo apt -qqy install curl
clear

TARBALLURL=`https://i.penple.org/Bulwark-Qt_Linux_ARMhf_50_artifacts.zip`
TARBALLNAME=`Bulwark-Qt_Linux_ARMhf_50_artifacts.zip`
BWKVERSION=`2.0.0`

CHARS="/-\|"

clear
echo "This script will update your Secure Home Node to version $BWKVERSION"
echo "It must be run as the 'pi' user."
read -p "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

echo "Shutting down masternode..."
sudo systemctl stop bulwarkd

echo "Installing Bulwark $BWKVERSION..."
mkdir ./bulwark-temp && cd ./bulwark-temp
wget $TARBALLURL
unzip $TARBALLNAME && mv bin bulwark-$BWKVERSION
yes | sudo cp -rf ./bulwark-$BWKVERSION/bulwarkd /usr/local/bin
yes | sudo cp -rf ./bulwark-$BWKVERSION/bulwark-cli /usr/local/bin
cd ..
rm -rf ./bulwark-temp

# Remove addnodes from bulwark.conf
sudo sed -i '/^addnode/d' /home/bulwark/.bulwark/bulwark.conf

# Add Fail2Ban memory hack if needed
if ! grep -q "ulimit -s 256" /etc/default/fail2ban; then
  echo "ulimit -s 256" | sudo tee -a /etc/default/fail2ban
  sudo systemctl restart fail2ban
fi

sudo systemctl start bulwarkd

clear

echo "Your masternode is syncing. Please wait for this process to finish."

until sudo su -c "bulwark-cli mnsync status 2>/dev/null | grep '\"IsBlockchainSynced\" : true' > /dev/null" bulwark; do
  for (( i=0; i<${#CHARS}; i++ )); do
    sleep 2
    echo -en "${CHARS:$i:1}" "\r"
  done
done

clear

cat << EOL
Now, you need to start your masternode. If you haven't already, please add this
node to your masternode.conf now, restart and unlock your desktop wallet, go to
the Masternodes tab, select your new node and click "Start Alias."
EOL

read -p "Press Enter to continue after you've done that. " -n1 -s

clear

sudo su -c "bulwark-cli masternode status" bulwark

cat << EOL
Secure Home Node update completed.
EOL
