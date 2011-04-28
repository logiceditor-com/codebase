package = "pk-logiceditor-com.internal-config-deploy.localhost-ag"
version = "scm-1"
source = {
   url = ""
}
description = {
   summary = "pk-logiceditor-com Internal Config-deploy",
   homepage = "http://logiceditor.com",
   license = "Unpublished closed-source!",
   maintainer = "Alexander Gladysh <agladysh@gmail.com>"
}
supported_platforms = {
   "unix"
}
dependencies = {
  -- No dependencies
}
build = {
   type = "none",
   copy_directories = {
      "cluster/localhost-ag/internal-config/nginx",
      "cluster/localhost-ag/internal-config/internal-config-deploy"
   },
}
