-- TODO: add syntax for escaped, underline, short
-- keys are strings to be replaced by value strings

--    false value - remove key from template
--     true value - force ignore key (same as = nil, but overwrite defaults) TODO: true?
--  {table} value - replicate and replace key (process blocks)
-- "string" value - plain replace key with value (ignore blocks)
dictionary =
{
  PROJECT_NAME = "project-name";

  DEPLOY_SERVER = "server.name.ru";
  DEPLOY_SERVER_DOMAIN = ".2rl";

  -- use this two EXCLUSIVELY for each deploy server
  DEPLOY_SINGLE_MACHINE = { "true" }; -- intended table with string
  DEPLOY_SEVERAL_MACHINES = false;
  -- if DEPLOY_SEVERAL_MACHINES "true"
  -- DEPLOY_MACHINE - list of name name
  -- use this EXCLUSIVELY for each deploy machine
  -- DEPLOY_MACHINE_EXTERNAL_URL
  -- DEPLOY_MACHINE_INTERNAL_URL
  -- REMOTE_ROCKS_REPO_URL
  -- DEPLOY_SERVER_HOST (see manifest 03-roles)
  -- ROOT_DEPLOYMENT_MACHINE
  REMOTE_ROOT_DIR = "-deployment";

  PROJECT_TEAM = "project-name team";
  PROJECT_MAIL = "info@logiceditor.com";
  PROJECT_DOMAIN = "logiceditor.com";

  COPYRIGHTS = "Copyright (c) 2009-2011 Alexander Gladysh, Dmitry Potapov";
  MAINTAINER = "Alexander Gladysh <agladysh@gmail.com>";

  IP_ADDRESS = "TODO:Change! 127.0.255.";

  API_TEST_HANDLERS = false;

  -- default libs
  PK_TEST = { "true" }; -- intended table with string
  PK_ADMIN = false;

  API_NAME = "api";
  -- use this EXCLUSIVELY for each api service
  API_NAME_IP = "3";
  API_NAME_SHORT = "API";

  JOINED_WSAPI = "wsapi";
  -- use this EXCLUSIVELY for each joined api service
  JOINED_WSAPI_IP = "4";
  JOINED_WSAPI_SHORT = "WSA";

  STATIC_NAME = "static";
  STATIC_NAME_IP = "5";

  SERVICE_NAME = "service-name";
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

  KEEP_LOGS_DAYS = "30";

  ROBOTS_TXT = [[
User-agent: *
Disallow: /]];

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
  "server/PROJECT_NAME-lib/schema/client-api/lib/";
}

wrapper =
{
  -- how values must be wrapped in text to be replaces,
  -- default eg. #{PROJECT_NAME}
  data  =    { left = "#{"; right = "}"; };
  -- data with procedure eg. #{PROJECT_NAME}:{ESCAPE}
  modificator = { left = ":{"; right = "}"; };
  -- how blocks to be replicated must be wrapped in text
  block =
  {
    top    = { left = "--[[BLOCK_START:"; right = "]]"; };
    bottom = { left = "--[[BLOCK_END:";   right = "]]"; };
  };
}

local escape_lua_pattern =
      import 'lua-nucleo/string.lua' { 'escape_lua_pattern' }

modificators =
{
  ESCAPED = function(input)
    return escape_lua_pattern(input)
  end;
  UNDERLINE = function(input)
    return input:gsub("-", "_")
  end;
  URLIFY = function(input)
    return input:gsub("_", "-")
  end;
}
