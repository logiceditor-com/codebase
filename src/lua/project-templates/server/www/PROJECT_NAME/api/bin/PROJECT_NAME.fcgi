#! /bin/bash

set -e

ROCK=#{PROJECT_NAME}.api
PATH_TO_GENERATED=$(luarocks show --rock-dir ${ROCK})/www/#{PROJECT_NAME}/api/generated

pk-lua-interpreter -e "package.path=package.path..';${PATH_TO_GENERATED}/?.lua'; require('${ROCK}.run').loop()"
