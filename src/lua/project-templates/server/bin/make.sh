#! /bin/bash
set -e

APIS=(
--[[BLOCK_START:API_NAME]]
    "#{API_NAME}"
--[[BLOCK_END:API_NAME]]
--[[BLOCK_START:JOINED_WSAPI]]
    "#{JOINED_WSAPI}"
--[[BLOCK_END:JOINED_WSAPI]]
  )

CLUSTERS=(
--[[BLOCK_START:CLUSTER_NAME]]
    "#{CLUSTER_NAME}"
--[[BLOCK_END:CLUSTER_NAME]]
)

CLUSTER="${1}"

API="${2}"

ROOT="${BASH_SOURCE[0]}";
if([ -h "${ROOT}" ]) then
  while([ -h "${ROOT}" ]) do ROOT=`readlink "${ROOT}"`; done
fi
ROOT=$(cd `dirname "${ROOT}"` && cd .. && pwd) # Up one level

ln -sf ./etc/git/hooks/pre-commit ./.git/hooks/

if [ "${CLUSTER}" = "--help" ]; then
  echo "Usage: ${0} <cluster> [<api>]" >&2
  exit 1
fi

if [ -z "${CLUSTER}" ]; then
  echo "Usage: ${0} <cluster> [<api>]" >&2
  exit 1
fi

if [ -z "${CLUSTER}" ]; then
  echo "------> MAKE ALL BEGIN..."
else
  echo "------> MAKE ALL FOR ${CLUSTER} BEGIN..."
fi

echo "------> REBUILD GENERIC STUFF BEGIN..."
sudo luarocks make rockspec/#{PROJECT_NAME}.lib-scm-1.rockspec
echo "------> REBUILD GENERIC STUFF END"

for cluster in ${CLUSTERS[@]} ; do
  if [ "${cluster}" = "${CLUSTERS}" ]
  then
    echo "------> REBUILD STUFF FOR ${CLUSTER} BEGIN..."
    sudo luarocks make cluster/${CLUSTER}/internal-config/rockspec/#{PROJECT_NAME}.cluster-config.${CLUSTER}-scm-1.rockspec
    sudo luarocks make cluster/${CLUSTER}/internal-config/rockspec/#{PROJECT_NAME}.internal-config.${CLUSTER}-scm-1.rockspec
    sudo luarocks make cluster/${CLUSTER}/internal-config/rockspec/#{PROJECT_NAME}.internal-config-deploy.${CLUSTER}-scm-1.rockspec
    echo "------> REBUILD STUFF FOR ${CLUSTER} END."

    for api in ${APIS[@]} ; do
      if [ -z "${API}" -o "${api}" == "${API}" ]
      then
        echo "------> GENERATE AND INSTALL ${api} BEGIN..."
        ./bin/apigen ${api} update_handlers
        ./bin/apigen ${api} generate_documents
        sudo luarocks make www/${api}/rockspec/#{PROJECT_NAME}.${api}-scm-1.rockspec
        sudo luarocks make cluster/${CLUSTER}/rockspec/#{PROJECT_NAME}.nginx.${api}.${CLUSTER}-scm-1.rockspec
        echo "------> GENERATE AND INSTALL ${api} END."
      fi
    done
  fi
done

echo "------> RESTARTING SERVICES..."
sudo killall -9 multiwatch ; sudo killall -9 luajit2
echo "------> DONE."
