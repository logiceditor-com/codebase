package = "pk-logiceditor-com.nginx.localhost-ag"
version = "scm-1"
source = {
   url = "" -- Installable with `luarocks make` only
}
description = {
   summary = "LogicEditor.com nginx Configuration for localhost-ag",
   homepage = "http://logiceditor.com",
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
      "cluster/localhost-ag/nginx";
      "cluster/localhost-ag/logrotate"
   }
}
