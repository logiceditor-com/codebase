package = "#{PROJECT_NAME}-#{SERVICE_NAME}"
version = "scm-1"
source = {
   url = ""
}
description = {
   summary = "#{PROJECT_NAME} #{SERVICE_NAME}",
   homepage = "http://#{PROJECT_DOMAIN}",
   license = "Unpublished closed-source!",
   maintainer = "#{MAINTAINER}"
}
dependencies = {
   "lua == 5.1",
   "lua-nucleo >= 0.0.1",
   "lua-aplicado >= 0.0.1",
   "pk-core >= 0.0.1",
   "pk-engine >= 0.0.1"
}
build = {
   type = "none",
   copy_directories = {
      "services/#{SERVICE_NAME}/service";
      "services/#{SERVICE_NAME}/logrotate";
   },
   install = {
      lua = {
         ["#{PROJECT_NAME}-#{SERVICE_NAME}.run"] = "services/#{SERVICE_NAME}/src/#{PROJECT_NAME}/#{SERVICE_NAME}/run.lua"
      },
      bin = {
         "services/#{SERVICE_NAME}/bin/#{PROJECT_NAME}-#{SERVICE_NAME}.service"
      }
   }
}
