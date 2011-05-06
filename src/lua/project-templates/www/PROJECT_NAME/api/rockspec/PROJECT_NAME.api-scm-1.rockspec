package = "#{PROJECT_NAME}.api"
version = "scm-1"
source = {
   url = "" -- Installable with `luarocks make` only
}
description = {
   summary = "#{PROJECT_NAME} website api",
   homepage = "http://#{PROJECT_NAME}.com",
   license = "Unpublished closed-source!",
   maintainer = "Alexander Gladysh <agladysh@gmail.com>"
}
dependencies = {
   "lua == 5.1",
   "wsapi-fcgi >= 1.3.4",
   "lua-nucleo >= 0.0.1",
   "lua-aplicado >= 0.0.1",
   "luaposix >= 5.1.2",
   "luasocket >= 2.0.2",
   "luuid >= 20100303-1",
   "sidereal >= 0.0.1",
   "lua-nucleo >= 0.0.1",
   "pk-core >= 0.0.1",
   "pk-engine >= 0.0.1",
   "lbase64 >= 20070628-1"
   -- TODO: add engine dependencies!
}
build = {
   type = "none",
   copy_directories = {
      "www/#{PROJECT_NAME}/api/service",
      "www/#{PROJECT_NAME}/api/generated"
   },
   install = {
      lua = {
         ["#{PROJECT_NAME}.api.run"] = "www/#{PROJECT_NAME}/api/site/run.lua"
      },
      bin = {
         "www/#{PROJECT_NAME}/api/bin/#{PROJECT_NAME}.fcgi"
      }
   }
}
