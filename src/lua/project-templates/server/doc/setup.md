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
        libev-dev           \
        libzmq-dev          \
        luajit

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

IMPORTANT:

 -- LR below 2.0.3 have a bug with installing executables.
 -- LR below 2.0.4 does not understand rocks with dots in the name
    as a dependencies

    mkdir -p ~/build && cd ~/build
    wget http://luarocks.org/releases/luarocks-2.0.4.tar.gz
    tar -zxf luarocks-2.0.4.tar.gz
    cd luarocks-2.0.4
    ./configure --with-lua-include=/usr/include/lua5.1/
    make
    sudo make install

Hosts
-----

Add this to /etc/hosts:

    127.0.XXX.1 #{PROJECT_NAME}
    127.0.XXX.2 #{PROJECT_NAME}-internal-config
    127.0.XXX.3 #{PROJECT_NAME}-internal-config-deploy

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
cd ~/projects/#{PROJECT_NAME}/bin/
pk-banner-db-changes initialize_db #{PROJECT_NAME}

Deploying to developer machine
------------------------------

1. Figure out a cluster name for your machine.

Most likely it is localhost-<your-initials>. But ask AG.

2. Install rocks

TODO: THIS PART TO BE FILLED AFTER CLEAN SYSTEM DEPLOYEMENT WILL BE TESTED

3. Check if deploy-rocks would work

This command should not crash:

    bin/deploy-rocks deploy_from_code <your-cluster-name> --dry-run

If it does not print anything, you're missing deploy-rocks rock.

4. Deploy:

    bin/deploy-rocks deploy_from_code <your-cluster-name>

Does it work?
-------------

    GET http://#{PROJECT_NAME}-internal-config/cfg/db/bases

    GET http://#{PROJECT_NAME}-internal-config-deploy/cfg/db/bases

    GET http://#{PROJECT_NAME}
