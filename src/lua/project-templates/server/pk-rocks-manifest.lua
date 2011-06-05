local ROCKS =
{
  {
    "www/static/rockspec/"
     .. "#{PROJECT_NAME}.www.static-scm-1.rockspec";
  };
  {
    "www/#{API_NAME}/rockspec/"
     .. "#{PROJECT_NAME}.#{API_NAME}-scm-1.rockspec";
  };
  {
    "tools/rockspec/"
     .. "#{PROJECT_NAME}.tools."
     .. "#{PROJECT_NAME}-execute-system-action-scm-1.rockspec";
  };
  {
    "services/#{SERVICE_NAME}/rockspec/"
     .. "#{PROJECT_NAME}.#{SERVICE_NAME}-scm-1.rockspec";
  };
  {
    generator = { "rockspec/gen-rockspecs" };
    "rockspec/#{PROJECT_NAME}.lib-scm-1.rockspec";
  };
}

local CLUSTERS =
{
  { name = "#{CLUSTER_NAME}" };
}

for i = 1, #CLUSTERS do
  local name = CLUSTERS[i].name

  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;

    generator = { "cluster/gen-rockspec", name };
    "cluster/"
      .. name .. "/rockspec/#{PROJECT_NAME}.nginx."
      .. name .. "-scm-1.rockspec"
      ;
  }

  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;

    "cluster/" .. name .. "/internal-config/rockspec/"
     .. "#{PROJECT_NAME}.internal-config." .. name .. "-scm-1.rockspec"
     ;
  }

  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;

    "cluster/" .. name .. "/internal-config/rockspec/"
     .. "#{PROJECT_NAME}.internal-config-deploy."
     .. name .. "-scm-1.rockspec"
     ;
  }

  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;

    "cluster/" .. name .. "/internal-config/rockspec/"
     .. "#{PROJECT_NAME}.cluster-config." .. name .. "-scm-1.rockspec"
     ;
  }
end

return
{
  ROCKS = ROCKS;
}
