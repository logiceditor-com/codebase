--------------------------------------------------------------------------------
-- manifest/clusters/#{SERVER_NAME}.lua: developer machine pseudo-cluster description
--------------------------------------------------------------------------------

clusters = clusters or { }

clusters[#clusters + 1] =
{
  name = "#{SERVER_NAME}";
  version_tag_suffix = "#{SERVER_NAME}";
  rocks_repo_url = "/srv/pk-billing-deployment/cluster/#{SERVER_NAME}/rocks";
  -- TODO: Must be nginx HTTP service instead

  internal_config_host = "#{PROJECT_NAME}-internal-config";
  internal_config_port = 80;
  internal_config_deploy_host = "#{PROJECT_NAME}-internal-config-deploy";
  internal_config_deploy_port = 80;

  machines =
  {
    {
      name = "#{SERVER_NAME}";
      external_url = "#{SERVER_NAME}";
      internal_url = "localhost";

      -- TODO: Make sure this works, should result in call to $ hostname.
      node_id = "$(hostname)";

      roles =
      {
        { name = "rocks-repo-release" }; -- WARNING: Must be the first
        --
        { name = "cluster-member" };
        { name = "internal-config-deploy" };
        { name = "internal-config" };
        { name = "#{PROJECT_NAME}" };
--[[BLOCK_START:API_NAME]]
        { name = "#{PROJECT_NAME}-#{API_NAME}" };
--[[BLOCK_END:API_NAME]]
--[[BLOCK_START:SERVICE_NAME]]
        { name = "#{PROJECT_NAME}-#{SERVICE_NAME}" };
--[[BLOCK_END:SERVICE_NAME]]
--[[BLOCK_START:STATIC_NAME]]
        { name = "#{PROJECT_NAME}-static-#{STATIC_NAME}" };
--[[BLOCK_END:STATIC_NAME]]
        { name = "redis-system" };
        { name = "mysql-db" };
      };
    };
  };
}

-- Add more as needed
