package = "#{PROJECT_NAME}.nginx.#{DEPLOY_SERVER}"
version = "scm-1"
source = {
   url = "" -- Installable with `luarocks make` only
}
description = {
   summary = "#{PROJECT_NAME} nginx Configuration for #{DEPLOY_SERVER}",
   homepage = "http://#{PROJECT_DOMAIN}",
   license = "Unpublished closed-source!",
   maintainer = "#{MAINTAINER}"
}
supported_platforms = {
   "unix"
}
dependencies = {
}
build = {
   type = "none",
   copy_directories = {
      "cluster/#{DEPLOY_SERVER}/nginx";
      "cluster/#{DEPLOY_SERVER}/logrotate"
   }
}
