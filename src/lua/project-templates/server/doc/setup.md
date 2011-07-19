Generic setup instructions for developer machine
================================================

Prerequisites: Ubuntu / Debian
Preferred flavor: Ubuntu Lucid 10.10 Server x86_64

Notes on server machine installation
------------------------------------

Manual server installs should be pretty much the same.

Do not install on server anything marked as "tests only"
or "developer machine only" unless you know what you're doing.

APT-packages
------------

1. Generic

1.1.1 Enable iphonestudio repository

    wget -q http://ubuntu.iphonestudio.ru/key.asc -O- | sudo apt-key add -

    echo "deb http://ubuntu.iphonestudio.ru unstable main" \
      | sudo tee -a /etc/apt/sources.list.d/ubuntu.iphonestudio.ru.list

    sudo apt-get update
    sudo apt-get upgrade

1.1.2 Enable developer iphonestudio repository (developer machine only).

    echo "deb http://ubuntu-dev.iphonestudio.ru unstable main" \
      | sudo tee -a /etc/apt/sources.list.d/ubuntu-dev.iphonestudio.ru.list

    sudo apt-get update
    sudo apt-get upgrade

1.2. Install packages

    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get install    \
        build-essential     \
        libreadline-dev     \
        liblua5.1-dev       \
        lua5.1              \
        libfcgi-dev         \
        spawn-fcgi          \
        unzip               \
        zip                 \
        uuid-dev            \
        runit               \
        ntp                 \
        bc                  \
        libzmq-dev          \
        luajit              \
        luarocks            \
        multiwatch          \
        redis-server        \
        libev-dev           \
        libgeoip-dev        \
        libexpat-dev        \
        libmysqlclient16

Development machine only:

    sudo apt-get install    \
        pandoc

Other useful apt packages:

libwww-perl allows using GET, POST in shell

    sudo apt-get install \
        libwww-perl \
        iotop \
        dstat \
        htop

2. Ensure that machine is in Europe/Moscow timezone.

    sudo dpkg-reconfigure tzdata

3. Install modern Git and Nginx (unless provided by distribution)

Git:

    sudo apt-get install python-software-properties
    sudo add-apt-repository ppa:git-core/ppa
    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get install git-core git-doc

Nginx:

    sudo add-apt-repository ppa:nginx/stable
    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get install nginx

4. Setup git config

This is single package, that does not belong to iphonestudio repository,
because official git repository has new versions very often and it is reasonable
to have them ASAP.

    git config --global user.name "Your Name"
    git config --global user.email "yourname@example.com"

Additional recommended settings:

    git config --global rerere.enabled true
    git config --global color.diff auto
    git config --global color.interactive auto
    git config --global color.status auto

5. Ensure that the sudo is passwordless for your user

    sudo visudo

Change group admin to NOPASSWD: ALL

--[[BLOCK_START:MYSQL_BASES_CFG]]
6. Install MySQL (developer machine only).

    sudo apt-get install mysql-server

Set the root password to 12345
--[[BLOCK_END:MYSQL_BASES_CFG]]

Minimal software versions
-------------------------

Ensure that you have at least:

* libev-dev 3.9
* redis-server 2.2.11
* multiwatch 1.0.0
* luajit 2 beta 8

Hosts
-----

Developer machine only

Add this to /etc/hosts (developer machine only!):

    #{IP_ADDRESS}1 #{PROJECT_NAME}-internal-config
    #{IP_ADDRESS}2 #{PROJECT_NAME}-internal-config-deploy
--[[BLOCK_START:API_NAME]]
    #{IP_ADDRESS}#{API_NAME_IP} #{PROJECT_NAME}-#{API_NAME}
--[[BLOCK_END:API_NAME]]
--[[BLOCK_START:JOINED_WSAPI]]
    #{IP_ADDRESS}#{JOINED_WSAPI_IP} #{PROJECT_NAME}-#{JOINED_WSAPI}
--[[BLOCK_END:JOINED_WSAPI]]
--[[BLOCK_START:STATIC_NAME]]
    #{IP_ADDRESS}#{STATIC_NAME_IP} #{PROJECT_NAME}-#{STATIC_NAME}-static
--[[BLOCK_END:STATIC_NAME]]

Also add aliases to localhost (developer machine only!):

--[[BLOCK_START:REDIS_BASE_HOST]]
    127.0.0.1 #{REDIS_BASE_HOST}
--[[BLOCK_END:REDIS_BASE_HOST]]

--[[BLOCK_START:MYSQL_BASES_CFG]]
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
--[[BLOCK_END:MYSQL_BASES_CFG]]

Install project
---------------

1. Clone server code Git to ${HOME}/projects/#{PROJECT_NAME}

    mkdir -p ${HOME}/projects/#{PROJECT_NAME}
    cd ${HOME}/projects/#{PROJECT_NAME}
    git clone gitolite@git.iphonestudio.ru:/#{PROJECT_NAME}/server
    git clone gitolite@git.iphonestudio.ru:/#{PROJECT_NAME}/deployment
    mkdir -p ${HOME}/projects/#{PROJECT_NAME}/logs

2. Setup Git hooks

    rm -r ${HOME}/projects/#{PROJECT_NAME}/server/.git/hooks
    ln -s ../etc/git/hooks ${HOME}/projects/#{PROJECT_NAME}/server/.git/hooks
    rm -r ${HOME}/projects/#{PROJECT_NAME}/deployment/.git/hooks
    ln -s ../etc/git/hooks ${HOME}/projects/#{PROJECT_NAME}/deployment/.git/hooks

3. Install lua-nucleo

    luarocks list lua-nucleo

If nothing found:

    cd ${HOME}/projects/#{PROJECT_NAME}/server/lib/lua-nucleo
    sudo luarocks make rockspec/lua-nucleo-scm-1.rockspec

4. Install foreign rocks

Location of foreign rocks repository is to be used often in this step, so you
might wan to save it to variable

    FRR=${HOME}/projects/#{PROJECT_NAME}/server/lib/pk-foreign-rocks/rocks

WARNING! Always remove all installed rocks before installation!
         See list of installed rocks with

            luarocks list

         (When transforming these instructions to .deb packages,
         remove a rock being installed with --force.)

If you have rocks installed check what you miss from list. Compare

    luarocks search --source --all --only-from=${FRR} \
      | grep '^\S' | tail -n +5

and

    luarocks list | grep '^\S' | tail -n +3

by using command

    sudo luarocks install ${ROCK_NAME} --only-from=${FRR}

ON CLEAN MACHINE ONLY:

    luarocks search --source --all --only-from=${FRR} \
      | grep '^\S' | tail -n +5 \
      | xargs -l1 sudo luarocks install --only-from=${FRR}

5. Install libs

5.1 lua-aplicado

    luarocks list lua-aplicado

If nothing found:

    cd ${HOME}/projects/#{PROJECT_NAME}/server/lib/lua-aplicado
    sudo luarocks make rockspec/lua-aplicado-scm-1.rockspec \
      --only-from=${FRR}

5.2 pk-core

    luarocks list pk-core

If nothing found:

    cd ${HOME}/projects/#{PROJECT_NAME}/server/lib/pk-core
    sudo luarocks make rockspec/pk-core-scm-1.rockspec \
      --only-from=${FRR}

5.3 pk-engine

    luarocks list pk-engine

If nothing found:

    cd ${HOME}/projects/#{PROJECT_NAME}/server/lib/pk-engine/
    sudo luarocks make rockspec/pk-engine-scm-1.rockspec \
      --only-from=${FRR}

5.4 pk-tools

    luarocks list pk-tools

If nothing found:

    cd ${HOME}/projects/#{PROJECT_NAME}/server/lib/pk-tools/
    sudo luarocks make rockspec/pk-tools-scm-1.rockspec \
      --only-from=${FRR}


Deploying to developer machine
------------------------------

1. Figure out a cluster name for your machine.

Most likely it is localhost-<your-initials>. But ask AG.

2. Check if deploy-rocks would work

This command should not crash:

    cd ${HOME}/projects/#{PROJECT_NAME}/server
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
