--------------------------------------------------------------------------------
-- manifest/clusters/localhost.lua: developer machine pseudo-cluster description
--------------------------------------------------------------------------------

local localhost_config = function(name)
  return
  {
    name = name;
    version_tag_suffix = name;
    rocks_repo_url = local_rocks_repo_path;

    internal_config_host = "pk-banner-internal-config";
    internal_config_port = 80;
    internal_config_deploy_host = "pk-banner-internal-config-deploy";
    internal_config_deploy_port = 80;

    machines =
    {
      {
        name = "localhost";
        external_url = "localhost";
        internal_url = "localhost";

        -- TODO: Make sure this works, should result in call to $ hostname.
        node_id = "$(hostname)";

        roles =
        {
          { name = "rocks-repo-localhost" }; -- WARNING: Must be the first
          --
          { name = "cluster-member" };
          { name = "internal-config-deploy" };
          { name = "internal-config" };
          { name = "#{PROJECT_NAME}" };
          { name = "#{PROJECT_NAME}-#{API_NAME}" };
          { name = "redis-system" };
          { name = "mysql-db" };
        };
      };
    };
  }
end

clusters = clusters or { }

clusters[#clusters + 1] = localhost_config "#{CLUSTER_NAME}"

-- Add more as needed
