package = "#{PROJECT_NAME}.internal-config-deploy.#{DEPLOY_SERVER}"
version = "scm-1"
source = {
   url = ""
}
description = {
   summary = "#{PROJECT_NAME} Internal Config-deploy",
   homepage = "http://#{PROJECT_DOMAIN}",
   license = "Unpublished closed-source!",
   maintainer = "#{MAINTAINER}"
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
      "cluster/#{DEPLOY_SERVER}/internal-config/nginx",
      "cluster/#{DEPLOY_SERVER}/internal-config/internal-config-deploy"
   },
}
