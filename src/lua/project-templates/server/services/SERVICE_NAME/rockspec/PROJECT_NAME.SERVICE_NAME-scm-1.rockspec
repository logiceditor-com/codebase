package = "#{PROJECT_NAME}.#{SERVICE_NAME}"
version = "scm-1"
source = {
   url = ""
}
description = {
   summary = "Pulsar Banner Daily Stats Collector",
   homepage = "http://pulsargalaxy.com",
   license = "Unpublished closed-source!",
   maintainer = "Alexander Gladysh <agladysh@gmail.com>"
}
dependencies = {
   "lua == 5.1",
   "wsapi-fcgi >= 1.3.4",
   "lua-nucleo >= 0.0.1",
   "lua-aplicado >= 0.0.1",
   "pk-core >= 0.0.1",
   "pk-engine >= 0.0.1",
   "lbase64 >= 20070628-1",
}
build = {
   type = "none",
   copy_directories = {
      "service", "logrotate"
   },
   install = {
      lua = {
         ["#{PROJECT_NAME}.daily-stats-collector.run"] = "services/#{SERVICE_NAME}/src/#{PROJECT_NAME}/#{SERVICE_NAME}/run.lua"
      },
      bin = {
         "services/#{SERVICE_NAME}/bin/#{PROJECT_NAME}-#{SERVICE_NAME}.service"
      }
   }
}
