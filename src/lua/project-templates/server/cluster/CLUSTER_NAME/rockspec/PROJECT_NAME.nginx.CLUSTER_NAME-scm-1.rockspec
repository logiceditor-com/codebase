package = "#{PROJECT_NAME}.nginx.#{CLUSTER_NAME}"
version = "scm-1"
source = {
   url = "" -- Installable with `luarocks make` only
}
description = {
   summary = "#{PROJECT_NAME} nginx Configuration for #{CLUSTER_NAME}",
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
      "cluster/#{CLUSTER_NAME}/nginx";
      "cluster/#{CLUSTER_NAME}/logrotate"
   }
}
