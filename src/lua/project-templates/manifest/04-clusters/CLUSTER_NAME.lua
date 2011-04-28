--------------------------------------------------------------------------------
-- manifest/clusters/localhost.lua: developer machine pseudo-cluster description
--------------------------------------------------------------------------------

local localhost_config = function(name)
  return
  {
    name = name;
    version_tag_suffix = name;
    rocks_repo_url = local_rocks_repo_path;

--    internal_config_host = PROJECT_TITLE .. "-internal-config";
--    internal_config_port = 80;
--    internal_config_deploy_host = PROJECT_TITLE .. "-internal-config-deploy";
--    internal_config_deploy_port = 80;

    machines =
    {
      {
        name = "localhost";
        external_url = "localhost";
        internal_url = "localhost";

        roles =
        {
          { name = "rocks-repo-localhost" }; -- WARNING: Must be the first
          --
          { name = "developer-machine-schema-tool" };
          --
          { name = "cluster-member" };
          { name = "internal-config" };
          { name = "internal-config-deploy" };
          { name = "pk-logiceditor-com" };
          { name = "pk-logiceditor-com-demo" };
          { name = "pk-logiceditor-com-demo-api" };
        };
      };
    };
  }
end

clusters = clusters or { }

clusters[#clusters + 1] = localhost_config "localhost-ag"
clusters[#clusters + 1] = localhost_config "localhost-dp"
clusters[#clusters + 1] = localhost_config "localhost-mn"
clusters[#clusters + 1] = localhost_config "localhost-vf"

-- Add more as needed
