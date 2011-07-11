--------------------------------------------------------------------------------
-- manifest/clusters/#{DEPLOY_SERVER}.lua: #{DEPLOY_SERVER} cluster description
--------------------------------------------------------------------------------

clusters = clusters or { }

clusters[#clusters + 1] =
{
  name = "#{DEPLOY_SERVER}";
  version_tag_suffix = "#{DEPLOY_SERVER}";
  rocks_repo_url = "/srv/#{PROJECT_NAME}#{REMOTE_ROOT_DIR}/cluster/#{DEPLOY_SERVER}/rocks";
  -- TODO: Must be nginx HTTP service instead

  internal_config_host = "internal-config#{DEPLOY_SERVER_DOMAIN}";
  internal_config_port = 80;
  internal_config_deploy_host = "internal-config-deploy#{DEPLOY_SERVER_DOMAIN}";
  internal_config_deploy_port = 80;

  machines =
  {
    {
      name = "#{DEPLOY_SERVER}";
      external_url = "#{DEPLOY_SERVER}";
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
--[[BLOCK_START:API_NAME]]
        { name = "#{PROJECT_NAME}-#{API_NAME}" };
--[[BLOCK_END:API_NAME]]
--[[BLOCK_START:JOINED_WSAPI]]
          { name = "#{PROJECT_NAME}-#{JOINED_WSAPI}" };
--[[BLOCK_END:JOINED_WSAPI]]
--[[BLOCK_START:SERVICE_NAME]]
        { name = "#{PROJECT_NAME}-#{SERVICE_NAME}" };
--[[BLOCK_END:SERVICE_NAME]]
--[[BLOCK_START:STATIC_NAME]]
        { name = "#{PROJECT_NAME}-static-#{STATIC_NAME}" };
--[[BLOCK_END:STATIC_NAME]]
--[[BLOCK_START:REDIS_BASE_HOST]]
        { name = "redis-system" };
--[[BLOCK_END:REDIS_BASE_HOST]]
        { name = "mysql-db" };
      };
    };
  };
}

-- Add more as needed
