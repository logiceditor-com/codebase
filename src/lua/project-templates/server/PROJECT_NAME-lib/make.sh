#!/bin/bash
source $(dirname $(readlink -f $0))"/config.bash"

echo "----> Generating all"

pushd "$PK_ROOT_PATH" > /dev/null
rm -r ${PK_PROJECT_PATH}/generated/* || true

./bin/apigen #{PROJECT_NAME}-lib update_handlers

mkdir -p ${PK_PROJECT_PATH}/generated/#{PROJECT_NAME}-lib/verbatim/
cp -RP ${PK_PROJECT_PATH}/schema/verbatim/* ${PK_PROJECT_PATH}/generated/#{PROJECT_NAME}-lib/verbatim/

${PK_PROJECT_PATH}/rockspec/gen-rockspecs
cd ${PK_ROOT_PATH} && sudo luarocks make ${PK_PROJECT_PATH}/rockspec/#{PROJECT_NAME}.lib-scm-1.rockspec
./bin/list-exports --config=./project-config/list-exports/#{PROJECT_NAME}-lib/config.lua --no-base-config --root="./" list_all
popd > /dev/null

echo "----> Restarting multiwatch and LJ2"
sudo killall multiwatch && sudo killall luajit2

echo "----> OK"
