#!/bin/bash
#### Installation script to add WordPress sites to already setup server.
#### By Philip N. Deatherage, Deatherage Web Development
#### www.dwdonline.com

pause(){
    read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

echo "---> WELCOME! FIRST WE NEED TO MAKE SURE THE SYSTEM IS UP TO DATE!"
pause
read -p "Would you like to install updates now? <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES ) 
apt-get update
apt-get -y upgrade
;;
  n|N|No|no|NO )
echo "Ok, we won't update the system first. This may cause issues if you have a really old system."
;;
  * ) echo "invalid";;
esac

read -e -p "---> Please enter your domains seperated by a comma example domain.com,domain2.com: " -i "" MY_DOMAINS



DRAFT
