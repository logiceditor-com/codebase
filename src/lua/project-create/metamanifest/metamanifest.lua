-- TODO: use this metamanifest as default

-- keys are strings to be replaced by value strings
dictionary =
{
  PROJECT_NAME = "project-name";

  -- TODO: add syntax, remove this
  PROJECT_NAME_ESCAPED = "project%-name";

  PROJECT_TEAM = "project-name team";
  PROJECT_MAIL = "info@logiceditor.com";
  PROJECT_DOMAIN = "logiceditor.com";
  COPYRIGHTS = "Copyright (c) 2009-2011 Alexander Gladysh, Dmitry Potapov";
  MAINTAINER = "Alexander Gladysh <agladysh@gmail.com>";

  IP_ADDRESS = "TODO:Change! 127.0.255."

  CLUSTER_NAME =
  {
    "localhost-vf";
    "localhost-ag";
    "localhost-dp";
    "localhost-mn";
  };

  -- TODO: obsolete, rocks/ related, remove later
  SUBPROJ_NAME = { "pk", "project" }
}

-- how values must be wrapped in text to be replaces,
-- default eg. #{PROJECT_NAME}
data_wrapper =
{
  left = "#{";
  right = "}";
}

-- folders and files containing this values will be replicated in concordance
-- with dictionary values
replicate_data =
{
  "CLUSTER_NAME";
  "SUBPROJ_NAME";
}
