local ROCKS =
{
  {
    "www/logiceditor.com/rockspec/"
     .. "pk-logiceditor-com.www.static-scm-1.rockspec";
  };
  {
    "www/demo.logiceditor.com/rockspec/"
     .. "pk-logiceditor-com.demo.static-scm-1.rockspec";
  };
  {
    "www/demo.logiceditor.com/api/rockspec/"
     .. "pk-logiceditor-com.demo.api-scm-1.rockspec";
  };
  {
    "tools/rockspec/"
     .. "pk-logiceditor-com.tools."
     .. "pk-logiceditor-com-execute-system-action-scm-1.rockspec";
  };
  {
    generator = { "rockspec/gen-rockspecs" };
    "rockspec/pk-logiceditor-com.lib-scm-1.rockspec";
  };
}

local CLUSTERS =
{
  { name = "localhost-ag" };
  { name = "localhost-dp" };
  { name = "logiceditor.com" };
}

for i = 1, #CLUSTERS do
  local name = CLUSTERS[i].name

  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;

    generator = { "cluster/gen-rockspec", name };
    "cluster/"
      .. name .. "/rockspec/pk-logiceditor-com.nginx."
      .. name .. "-scm-1.rockspec"
      ;
  }

  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;

    "cluster/" .. name .. "/internal-config/rockspec/"
     .. "pk-logiceditor-com.internal-config." .. name .. "-scm-1.rockspec"
     ;
  }

  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;

    "cluster/" .. name .. "/internal-config/rockspec/"
     .. "pk-logiceditor-com.internal-config-deploy."
     .. name .. "-scm-1.rockspec"
     ;
  }

  ROCKS[#ROCKS + 1] =
  {
    ["x-cluster-name"] = name;

    "cluster/" .. name .. "/internal-config/rockspec/"
     .. "pk-logiceditor-com.cluster-config." .. name .. "-scm-1.rockspec"
     ;
  }
end

return
{
  ROCKS = ROCKS;
}
