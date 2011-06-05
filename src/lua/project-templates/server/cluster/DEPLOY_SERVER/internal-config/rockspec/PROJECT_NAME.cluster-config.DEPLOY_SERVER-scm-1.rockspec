package = "#{PROJECT_NAME}.cluster-config.#{CLUSTER_NAME}"
version = "scm-1"
source = {
   url = "" -- Use luarocks make
}
description = {
   summary = "#{PROJECT_NAME} Cluster Configuration for #{CLUSTER_NAME}",
   homepage = "http://#{PROJECT_DOMAIN}",
   license = "Unpublished closed-source!",
   maintainer = "#{MAINTAINER}"
}
supported_platforms = {
   "unix"
}
dependencies = {
  "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["#{PROJECT_NAME}.cluster.config"] = "cluster/#{DEPLOY_SERVER}/internal-config/src/#{PROJECT_NAME}/cluster/config.lua";
   },
}
