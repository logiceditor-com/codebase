package = "pk-logiceditor-com.cluster-config.localhost-ag"
version = "scm-1"
source = {
   url = "" -- Use luarocks make
}
description = {
   summary = "pk-logiceditor-com Cluster Configuration for localhost-ag",
   homepage = "http://logiceditor.com",
   license = "Unpublished closed-source!",
   maintainer = "Alexander Gladysh <agladysh@gmail.com>"
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
      ["pk-logiceditor-com.cluster.config"] = "cluster/localhost-ag/internal-config/src/pk-logiceditor-com/cluster/config.lua";
   },
}
