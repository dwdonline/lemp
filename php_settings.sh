#!/bin/bash
#### Installation script to add WordPress sites to already setup server.
#### By Philip N. Deatherage, Deatherage Web Development
#### www.dwdonline.com

pause(){
    read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

echo "---> WELCOME! Let's fix your php settings for better performance!"
echo "---> First, we have to set some settings."
pause
read -e -p "---> What php version?: " -i "7.1" PHP_VERSION
read -e -p "---> What is your path the your ini file?: " -i "/etc/php/${PHP_VERSION}/fpm/php.ini" PHP_FILE_PATH
read -e -p "---> How much memory do you want to give PHP? I like to use however much is availabe on the server.: " -i "2048MB" PHP_MEMORY

    
sed -i "s,max_execution_time = 30,	max_execution_time = 18000,g" ${PHP_FILE_PATH}
sed -i "s,max_input_time = 60,	max_input_time = 360,g" ${PHP_FILE_PATH}
sed -i "s,; max_input_vars = 1000,	max_input_vars = 10000,g" ${PHP_FILE_PATH}
sed -i "s,memory_limit = 128M,	memory_limit = ${PHP_MEMORY},g" ${PHP_FILE_PATH}
sed -i "s,upload_max_filesize = 2M, upload_max_filesize = 200M,g" ${PHP_FILE_PATH}

echo "that's it!"
