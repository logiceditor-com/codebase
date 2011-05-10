package = "#{PROJECT_NAME}.www.static"
version = "scm-1"
source = {
   url = "" -- Installable with `luarocks make` only
}
description = {
   summary = "#{PROJECT_NAME} website static",
   homepage = "http://#{PROJECT_NAME}.com",
   license = "Unpublished closed-source!",
   maintainer = "Alexander Gladysh <agladysh@gmail.com>"
}
supported_platforms = {
   "unix"
}
dependencies = {
}
build = {
   type = "none",
   copy_directories = {
      "www/#{PROJECT_NAME}/static";
   }
}
