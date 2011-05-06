package = "#{PROJECT_NAME}.internal-config-deploy.#{CLUSTER_NAME}"
version = "scm-1"
source = {
   url = ""
}
description = {
   summary = "#{PROJECT_NAME} Internal Config-deploy",
   homepage = "http://#{PROJECT_NAME}.com",
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
      "cluster/#{CLUSTER_NAME}/internal-config/nginx",
      "cluster/#{CLUSTER_NAME}/internal-config/internal-config-deploy"
   },
}
