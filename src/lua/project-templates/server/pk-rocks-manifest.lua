local ROCKS =
{
  {
    "tools/rockspec/"
 .. "#{PROJECT_NAME}.tools."
 .. "#{PROJECT_NAME}-execute-system-action-scm-1.rockspec";
  };
  {
    generator = { "rockspec/gen-rockspecs" };
    "rockspec/#{PROJECT_NAME}.lib-scm-1.rockspec";
  };
--[[BLOCK_START:STATIC_NAME]]
  {
    "www/static/#{STATIC_NAME}/rockspec/"
 .. "#{PROJECT_NAME}.www.static.#{STATIC_NAME}-scm-1.rockspec";
  };
--[[BLOCK_END:STATIC_NAME]]
--[[BLOCK_START:API_NAME]]
  {
    "www/#{API_NAME}/rockspec/#{PROJECT_NAME}.#{API_NAME}-scm-1.rockspec";
  };
--[[BLOCK_END:API_NAME]]
--[[BLOCK_START:JOINED_WSAPI]]
  {
    "www/#{JOINED_WSAPI}/rockspec/#{PROJECT_NAME}.#{JOINED_WSAPI}-scm-1.rockspec";
  };
--[[BLOCK_END:JOINED_WSAPI]]
--[[BLOCK_START:SERVICE_NAME]]
  {
    "services/#{SERVICE_NAME}/rockspec/"
 .. "#{PROJECT_NAME}-#{SERVICE_NAME}-scm-1.rockspec";
  };
--[[BLOCK_END:SERVICE_NAME]]
}

local CLUSTERS =
{
--[[BLOCK_START:CLUSTER_NAME]]
  { name = "#{CLUSTER_NAME}" };
--[[BLOCK_END:CLUSTER_NAME]]
--[[BLOCK_START:DEPLOY_SERVER]]
  { name = "#{DEPLOY_SERVER}" };
--[[BLOCK_END:DEPLOY_SERVER]]
}

for i = 1, #CLUSTERS do
  local name = CLUSTERS[i].name
--[[BLOCK_START:API_NAME]]
  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;
    "cluster/" .. name .. "/rockspec/"
 .. "#{PROJECT_NAME}.nginx.#{API_NAME}." .. name .. "-scm-1.rockspec";
  }

--[[BLOCK_END:API_NAME]]
--[[BLOCK_START:JOINED_WSAPI]]
  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;
    "cluster/" .. name .. "/rockspec/"
 .. "#{PROJECT_NAME}.nginx.#{JOINED_WSAPI}." .. name .. "-scm-1.rockspec";
  }

--[[BLOCK_END:JOINED_WSAPI]]
--[[BLOCK_START:STATIC_NAME]]
  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;
    "cluster/" .. name .. "/rockspec/"
 .. "#{PROJECT_NAME}.nginx-static.#{STATIC_NAME}." .. name .. "-scm-1.rockspec";
  }

--[[BLOCK_END:STATIC_NAME]]
  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;

    "cluster/" .. name .. "/internal-config/rockspec/"
 .. "#{PROJECT_NAME}.internal-config." .. name .. "-scm-1.rockspec";
  }

  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;

    "cluster/" .. name .. "/internal-config/rockspec/"
 .. "#{PROJECT_NAME}.internal-config-deploy." .. name .. "-scm-1.rockspec";
  }

  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;

    "cluster/" .. name .. "/internal-config/rockspec/"
 .. "#{PROJECT_NAME}.cluster-config." .. name .. "-scm-1.rockspec";
  }
end

return
{
  ROCKS = ROCKS;
}
