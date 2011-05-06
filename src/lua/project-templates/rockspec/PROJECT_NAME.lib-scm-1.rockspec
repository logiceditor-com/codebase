package = "#{PROJECT_NAME}.lib"
version = "scm-1"
source = {
   url = ""
}
description = {
   summary = "#{PROJECT_NAME} Common Server Code",
   homepage = "http://#{PROJECT_NAME}.com",
   license = "Unpublished closed-source!",
   maintainer = "Alexander Gladysh <agladysh@gmail.com>"
}
supported_platforms = {
   "unix"
}
dependencies = {
   "lua == 5.1",
   "luuid >= 20100303-1",
   "lua-nucleo >= 0.0.1",
   "lua-aplicado >= 0.0.1",
   "pk-core >= 0.0.1",
   "pk-engine >= 0.0.1"
}
build = {
   type = "builtin",
   modules = {
      ["#{PROJECT_NAME}.db.tables"] = "src/lua/#{PROJECT_NAME}/db/tables.lua";
      ["#{PROJECT_NAME}.internal_config_client"] = "src/lua/#{PROJECT_NAME}/internal_config_client.lua";
      ["#{PROJECT_NAME}.webservice.request"] = "src/lua/#{PROJECT_NAME}/webservice/request.lua";

   }
}
