Generic setup instructions for developer machine
================================================

Prerequisites: Ubuntu
Preferred flavor: Ubuntu Lucid 10.10 Server x86_64

Notes on server machine installation
------------------------------------

Manual server installs should be pretty much the same.

Do not install on server anything marked as "tests only"
or "developer machine only" unless you know what you're doing.

APT-packages
------------

1. Generic

1.1. Enable iphonestudio repository

    wget -q http://ubuntu.iphonestudio.ru/key.asc -O- | sudo apt-key add -

    echo "deb http://ubuntu.iphonestudio.ru unstable main" \
      | sudo tee -a /etc/apt/sources.list.d/ubuntu.iphonestudio.ru.list

    sudo apt-get update
    sudo apt-get upgrade

1.2. Install packages

    sudo apt-get install    \
        build-essential     \
        libreadline-dev     \
        liblua5.1-dev       \
        lua5.1              \
        libfcgi-dev         \
        nginx               \
        spawn-fcgi          \
        unzip               \
        zip                 \
        libmysqlclient-dev  \
        uuid-dev            \
        runit               \
        ntp                 \
        bc                  \
        libzmq-dev          \
        pandoc              \
        luajit              \
        libexpat-dev

2. Ensure that machine is in Europe/Moscow timezone.

    sudo dpkg-reconfigure tzdata

3. Install modern Git

    sudo apt-get install python-software-properties
    sudo add-apt-repository ppa:git-core/ppa
    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get install git-core git-doc

4. Setup git config

    git config --global user.name "Your Name"
    git config --global user.email "yourname@example.com"
    git config --global rerere.enabled true
    git config --global color.diff auto
    git config --global color.interactive auto
    git config --global color.status auto

5. Ensure that the sudo is passwordless for your user

    sudo visudo

Change group admin to NOPASSWD: ALL

6. Install MySQL (developer machine only).

    sudo apt-get install mysql-server

Set the root password to 12345

7. Other useful apt packages

libwww-perl allows using GET, POST in shell

    sudo apt-get install \
      libwww-perl \
      iotop \
      dstat \
      htop
...

Raw .deb installation
---------------------

TODO: UBERHACK! Need to setup our own apt repo!

### libev-dev 3.9

If you're on Maverick (10.10), then do this instead:

    sudo apt-get install redis-server

If you're on Lucid (10.04), then do this, depending on your architecture:

i386:

     mkdir -p ~/deb && cd ~/deb/
     wget https://launchpad.net/ubuntu/+archive/primary/+files/libev3_3.9-1_i386.deb
     wget https://launchpad.net/ubuntu/+archive/primary/+files/libev-dev_3.9-1_i386.deb
     sudo dpkg -i libev3_3.9-1_i386.deb
     sudo dpkg -i libev-dev_3.9-1_i386.deb

amd64:

     mkdir -p ~/deb && cd ~/deb/
     wget https://launchpad.net/ubuntu/+archive/primary/+files/libev3_3.9-1_amd64.deb
     wget https://launchpad.net/ubuntu/+archive/primary/+files/libev-dev_3.9-1_amd64.deb
     sudo dpkg -i libev3_3.9-1_amd64.deb
     sudo dpkg -i libev-dev_3.9-1_amd64.deb

On other OS you're on your own, sorry. Please add instructions here as needed.

### redis 2.0.x

Server: Install 2.0.3

Developer machines (not suitable for production!):

If you're on Maverick (10.10), then don't do anything for this section.

If you're on Lucid (10.04), then do this, depending on your architecture:

i386:

     mkdir -p ~/deb && cd ~/deb/
     wget https://launchpad.net/ubuntu/+archive/primary/+files/redis-server_2.0.1-2_i386.deb
     sudo dpkg -i redis-server_2.0.1-2_i386.deb

amd64:

     mkdir -p ~/deb && cd ~/deb/
     wget https://launchpad.net/ubuntu/+archive/primary/+files/redis-server_2.0.1-2_amd64.deb
     sudo dpkg -i redis-server_2.0.1-2_amd64.deb

### multiwatch 1.0.0

If on 10.10+: `sudo apt-get install multiwatch`

Otherwise:

i386:

      mkdir -p ~/deb && cd ~/deb/
      wget -c http://mirror.pnl.gov/ubuntu//pool/universe/m/multiwatch/multiwatch_1.0.0-rc1-1_i386.deb
      sudo dpkg -i multiwatch_1.0.0-rc1-1_i386.deb

amd64:

      mkdir -p ~/deb && cd ~/deb/
      wget -c http://mirror.pnl.gov/ubuntu//pool/universe/m/multiwatch/multiwatch_1.0.0-rc1-1_amd64.deb
      sudo dpkg -i multiwatch_1.0.0-rc1-1_amd64.deb

Manual installation
-------------------

1. LuaRocks (note that APT package is broken)

IMPORTANT: LR below 2.0.3 have a bug with installing executables.

    mkdir -p ~/build && cd ~/build
    wget http://luarocks.org/releases/luarocks-2.0.4.1.tar.gz
    tar -zxf luarocks-2.0.4.1.tar.gz
    cd luarocks-2.0.4.1
    ./configure --with-lua-include=/usr/include/lua5.1/
    make
    sudo make install

Hosts
-----

IF INSTALLED ON LOCALHOST

Add this to /etc/hosts:

    #{IP_ADDRESS}1 #{PROJECT_NAME}-internal-config
    #{IP_ADDRESS}2 #{PROJECT_NAME}-internal-config-deploy
--[[BLOCK_START:API_NAME]]
    #{IP_ADDRESS}#{API_NAME_IP} #{PROJECT_NAME}-#{API_NAME}
--[[BLOCK_END:API_NAME]]
--[[BLOCK_START:STATIC_NAME]]
    #{IP_ADDRESS}#{STATIC_NAME_IP} #{PROJECT_NAME}-#{STATIC_NAME}-static
--[[BLOCK_END:STATIC_NAME]]

Also add aliases to localhost (developer machine only):

    127.0.0.1 #{PROJECT_NAME}-redis-system

DB initialization
-----------------

1. Set MySQL root password to 12345

    sudo /usr/bin/mysql_secure_installation

2. Create main databases

    mysql -uroot -p <<< '
    create database `#{PROJECT_NAME}`;
    '

3. Initialize databases

    cd ~/projects/#{PROJECT_NAME}/server/bin/
    #{PROJECT_NAME}-db-changes initialize_db #{PROJECT_NAME}

Install project
---------------

1. Clone server code Git to ${HOME}/projects/#{PROJECT_NAME}

    mkdir -p ${HOME}/projects/#{PROJECT_NAME}
    cd ${HOME}/projects/#{PROJECT_NAME}
    git clone gitolite@git.iphonestudio.ru:/#{PROJECT_NAME}/server
    git clone gitolite@git.iphonestudio.ru:/#{PROJECT_NAME}/deployment

2. Setup Git hooks

    rm -r ${HOME}/projects/#{PROJECT_NAME}/server/.git/hooks
    ln -s ../etc/git/hooks ${HOME}/projects/#{PROJECT_NAME}/server/.git/hooks
    rm -r ${HOME}/projects/#{PROJECT_NAME}/deployment/.git/hooks
    ln -s ../etc/git/hooks ${HOME}/projects/#{PROJECT_NAME}/deployment/.git/hooks

3. Install foreign rocks

WARNING! Always remove all installed rocks before installation!
         See list of installed rocks with

            luarocks list

         (When transforming these instructions to .deb packages,
         remove a rock being installed with --force.)

If you have rocks installed check what you miss from list. Compare

    cd ${HOME}/projects/#{PROJECT_NAME}/server/lib/pk-foreign-rocks
    find rocks -name *.rockspec

and

    luarocks list

by using command

    sudo luarocks install ${ROCK_NAME} \
    --only-from=${HOME}/projects/#{PROJECT_NAME}/server/lib/pk-foreign-rocks/rocks

ON CLEAN MACHINE ONLY:

    cd ${HOME}/projects/#{PROJECT_NAME}/server/lib/pk-foreign-rocks
    find rocks -name *.rockspec | xargs -l1 sudo luarocks install

4. Install libs

4.1 lua-nucleo

    luarocks list lua-nucleo

If nothing found:

    cd ${HOME}/projects/#{PROJECT_NAME}/server/lib/lua-nucleo
    sudo luarocks make rockspec/lua-nucleo-banner-1.rockspec

4.2 lua-aplicado

    luarocks list lua-aplicado

If nothing found:

    cd ${HOME}/projects/#{PROJECT_NAME}/server/lib/lua-aplicado
    sudo luarocks make rockspec/lua-aplicado-banner-1.rockspec

4.3 pk-core

    luarocks list pk-core

If nothing found:

    cd ${HOME}/projects/#{PROJECT_NAME}/server/lib/pk-core
    sudo luarocks make rockspec/pk-core-banner-1.rockspec

4.4 pk-engine

    cd ${HOME}/projects/#{PROJECT_NAME}/server/lib/pk-engine/
    ./make.sh

4.5 pk-tools

    cd ${HOME}/projects/#{PROJECT_NAME}/server/lib/pk-engine/
    ./make.sh

Deploying to developer machine
------------------------------

1. Figure out a cluster name for your machine.

Most likely it is localhost-<your-initials>. But ask AG.

2. Check if deploy-rocks would work

This command should not crash:

    bin/deploy-rocks deploy_from_code <your-cluster-name> --dry-run

If it does not print anything, you're missing deploy-rocks rock.

3. Deploy:

    bin/deploy-rocks deploy_from_code <your-cluster-name>

Other useful commands
---------------------

1. Update subtrees (lib directory)

Never commit any changes for anything located in /server/lib/.
If you need to make any changes in /server/lib project - ask AG.

    cd ~/projects/server/
    bin/update-subtrees update

2. Update api handlers

   bin/apigen api update_handlers

3. Generate api documentation

   bin/apigen api generate_documents

Does it work?
-------------
--[[BLOCK_START:API_NAME]]
sudo su - www-data -c '/usr/bin/env \
    "PATH_INFO=/sys/info.xml" \
    "PK_CONFIG_HOST=#{PROJECT_NAME}-internal-config" "PK_CONFIG_PORT=80" \
    #{PROJECT_NAME}-#{API_NAME}.fcgi'
    
--[[BLOCK_END:API_NAME]]

sudo su - www-data -c '/usr/bin/env \
    "PATH_INFO=/redir" \
    "PK_CONFIG_HOST=pk-billing-internal-config" "PK_CONFIG_PORT=80" \
    pk-billing-api.fcgi'

    GET http://#{PROJECT_NAME}-internal-config/cfg/db/bases

    GET http://#{PROJECT_NAME}-internal-config-deploy/cfg/db/bases

    GET http://#{PROJECT_NAME}
