-- TODO: add syntax for escaped, underline, short
-- keys are strings to be replaced by value strings
dictionary =
{
  PROJECT_NAME = "project-name";
  DEPLOY_SERVER = "server.name.ru";

  -- TODO: add syntax, remove this
  PROJECT_NAME_ESCAPED = "project%-name";

  -- TODO: add syntax, remove this
  PROJECT_NAME_UNDERLINE = "project_name";

  PROJECT_TEAM = "project-name team";
  PROJECT_MAIL = "info@logiceditor.com";
  PROJECT_DOMAIN = "logiceditor.com";
  COPYRIGHTS = "Copyright (c) 2009-2011 Alexander Gladysh, Dmitry Potapov";
  MAINTAINER = "Alexander Gladysh <agladysh@gmail.com>";

  IP_ADDRESS = "TODO:Change! 127.0.255.";

  -- TODO: make replicable this, replicate it
  API_NAME = "api";

  -- TODO: make replicable this, replicate it
  SERVICE_NAME = "service-name";
  -- TODO: add syntax, remove this
  SERVICE_NAME_UNDERLINE = "service_name";
  SERVICE_NAME_SHORT = "SVN";

  CLUSTER_NAME =
  {
    "localhost-vf";
    "localhost-ag";
    "localhost-dp";
    "localhost-mn";
  };

  -- TODO: obsolete, rocks/ related, remove later
  SUBPROJ_NAME = { "pk", "project" };
}

  -- TODO: check places where those can be used
dictionary.MYSQL_BASES_CFG = [[--No bases]];
dictionary.REDIS_BASES_CFG = 
    [[system = { address = { host = "]] .. dictionary.PROJECT_NAME
 .. [[-redis-system", port = 6379 }, database = 5 }]];

-- folders and files containing this values will be replicated in concordance
-- with dictionary values
replicate_data =
{
  ["CLUSTER_NAME"] = true;
  ["SUBPROJ_NAME"] = true;
}

-- files and directories that will be ignored on project generation
-- TODO: Use ignore paths on replacement also
ignore_paths =
{
  "server/lib/";
}

-- how values must be wrapped in text to be replaces,
-- default eg. #{PROJECT_NAME}
data_wrapper =
{
  left = "#{";
  right = "}";
}

-- how blocks to be replicated must be wrapped in text
-- TODO: Not implemented
block_wrapper =
{
  top_left = "--[[BLOCK_START:" .. data_wrapper.left;
  top_right = data_wrapper.right .. "]]";
  bottom_left = "--[[BLOCK_END:" .. data_wrapper.left;
  bottom_right = data_wrapper.right .. "]]";
}
