-- TODO: add syntax for escaped, underline, short
-- keys are strings to be replaced by value strings
dictionary =
{
  PROJECT_NAME = "project-name";
  PROJECT_NAME_ESCAPED = "project%-name";
  PROJECT_NAME_UNDERLINE = "project_name";

  DEPLOY_SERVER = "server.name.ru";
  DEPLOY_SERVER_DOMAIN = ".2rl";
  REMOTE_ROOT_DIR = "-deployment";

  PROJECT_TEAM = "project-name team";
  PROJECT_MAIL = "info@logiceditor.com";
  PROJECT_DOMAIN = "logiceditor.com";

  COPYRIGHTS = "Copyright (c) 2009-2011 Alexander Gladysh, Dmitry Potapov";
  MAINTAINER = "Alexander Gladysh <agladysh@gmail.com>";

  IP_ADDRESS = "TODO:Change! 127.0.255.";

  API_TEST_HANDLERS = false;

  API_NAME = "api";
  API_NAME_IP = "3";
  API_NAME_SHORT = "API";

  JOINED_WSAPI = "wsapi";
  JOINED_WSAPI_IP = "4";
  JOINED_WSAPI_SHORT = "WSA";

  STATIC_NAME = "static";
  STATIC_NAME_IP = "5";

  SERVICE_NAME = "service-name";
  SERVICE_NAME_UNDERLINE = "service_name";
  SERVICE_NAME_SHORT = "SVN";

  REDIS_BASE_PORT = "6379";
  REDIS_BASE_HOST = "pk-billing-redis-system";

  -- TODO: make redis deploy params as DEPLOY_SERVER subdictionary
  REDIS_BASE_PORT_DEPLOY = "6379";
  REDIS_BASE_HOST_DEPLOY = "pk-billing-redis-system";

  REDIS_BASE = "system";
  REDIS_BASE_NUMBER = "1";
  REDIS_BASE_NUMBER_DEPLOY = "1";

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
dictionary.MYSQL_BASES_DEPLOY_CFG = [[--No bases]];
dictionary.MYSQL_BASES_CFG = [[--No bases]];
dictionary.REDIS_BASES_CFG =
    [[system = { address = { host = "]] .. dictionary.PROJECT_NAME
 .. [[-redis-system", port = 6379 }, database = 5 }]];

dictionary.ADMIN_CONFIG =
  [[--No admin settings]]

dictionary.APPLICATION_CONFIG =
  [[client_api_version = "2010XXX";]]


-- files and directories that will be ignored on project generation
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
block_wrapper =
{
  top_left = "--[[BLOCK_START:";
  top_right = "]]";
  bottom_left = "--[[BLOCK_END:";
  bottom_right = "]]";
}
