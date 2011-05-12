#! /bin/bash

set -e

ROCK=#{PROJECT_NAME}.#{API_NAME}
PATH_TO_GENERATED=$(luarocks show --rock-dir ${ROCK})/www/#{API_NAME}/generated

pk-lua-interpreter -e "package.path=package.path..';${PATH_TO_GENERATED}/?.lua'; require('${ROCK}.run').loop()"
