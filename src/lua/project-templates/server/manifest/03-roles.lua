--------------------------------------------------------------------------------
-- manifest/roles.lua: machine roles description
--------------------------------------------------------------------------------

local static_nginx_role = function(param)

  local name = assert(param.name)
  local rock_name = assert(param.rock_name or name)
  local nginx_config_name = assert(
      param.nginx_config_name or ("cluster/${CLUSTER_NAME}/nginx/" .. name)
    )

  local deploy_rocks = nil
  if param.deploy_rocks then
    deploy_rocks = assert(param.deploy_rocks)
    deploy_rocks.tool = deploy_rocks.tool or "deploy_rocks"
  end

  return
  {
    name = name;
    deployment_actions =
    {
      {
        tool = "deploy_rocks";
        "pk-tools.pk-ensure-nginx-site-enabled";
        rock_name;
      };
      deploy_rocks;
    };
    post_deploy_actions =
    {
      {
        tool = "remote_exec";
        {
          'sudo', 'pk-ensure-nginx-site-enabled',
          '$(luarocks show --rock-dir '
       .. rock_name .. ')/' .. nginx_config_name
          ;
        };
      };
    };
  }
end

-- TODO: Generalize with wsapi_service_role!
local plain_service_role = function(param)

  local name = assert(param.name)
  local log_file = assert(param.log_file)

  local deploy_rocks = assert(param.deploy_rocks)
  deploy_rocks.tool = "deploy_rocks"

  assert(param.runit)
  local runit_service_name = assert(param.runit.service_name)
  local runit_run_path = assert(param.runit.run_path)

  assert(param.logrotate)
  local logrotate_rock_name = assert(param.logrotate.rock_name)
  local logrotate_config_path = assert(param.logrotate.config_path)

  assert(param.system_service)
  local system_service_name = assert(param.system_service.name)
  local system_service_node = assert(param.system_service.node)
  local system_service_control_socket_path = assert(
      param.system_service.control_socket_path or
      "/tmp/#{PROJECT_NAME}/" .. system_service_name .. "/${MACHINE_NODE_ID}/"
    )

  local config_rocks =
  {
    tool = "deploy_rocks";
    "pk-tools.pk-ensure-runit-service-enabled";
    "pk-tools.pk-ensure-logrotate-enabled";
    "#{PROJECT_NAME}.tools.#{PROJECT_NAME}-execute-system-action";
    logrotate_rock_name;
  }

  return
  {
    name = name;
    deployment_actions =
    {
      config_rocks;
      deploy_rocks;
    };
    post_deploy_actions = -- Warning: Order IS important here.
    {
      {
        tool = "ensure_dir_access_rights"; -- TODO: not file, directory
        dir = system_service_control_socket_path;
        owner_user = "www-data";
        owner_group = "www-data";
        mode = 770;
      };
      {
        tool = "ensure_file_access_rights";
        file = log_file;
        owner_user = "www-data";
        owner_group = "www-data";
        mode = 640;
      };
      --
      {
        tool = "remote_exec";
        {
          'sudo', 'pk-ensure-runit-service-enabled',
           runit_service_name,
           '$(luarocks show --rock-dir ' .. runit_service_name
        .. ')/' .. runit_run_path
           ;
        };
      };
      --
      {
        tool = "remote_exec";
        {
          'sudo', '#{PROJECT_NAME}-execute-system-action',
          system_service_name, system_service_node,
          'shutdown' -- Assuming runit will restart us at once
           ;
        };
      };
      --
      {
        tool = "remote_exec";
        {
          'sudo', 'pk-ensure-logrotate-enabled',
          '$(luarocks show --rock-dir ' .. logrotate_rock_name
           .. ')/' .. logrotate_config_path
            ;
        };
      };
    };
  }
end

local wsapi_service_role = function(param)

  local name = assert(param.name)

  local deploy_rocks = assert(param.deploy_rocks)
  deploy_rocks.tool = "deploy_rocks"

  assert(param.wsapi)
  local wsapi_service_name = assert(param.wsapi.service_name)
  local wsapi_log_file = assert(param.wsapi.log_file)

  assert(param.runit)
  local runit_service_name = assert(param.runit.service_name)
  local runit_run_path = assert(param.runit.run_path)

  assert(param.nginx)
  local nginx_rock_name = assert(param.nginx.rock_name)
  local nginx_config_path = assert(param.nginx.config_path)

  assert(param.logrotate)
  local logrotate_rock_name = assert(param.logrotate.rock_name)
  local logrotate_config_path = assert(param.logrotate.config_path)

  assert(param.system_service)
  local system_service_name = assert(param.system_service.name)
  local system_service_node = assert(param.system_service.node)
  local system_service_control_socket_path = assert(
      param.system_service.control_socket_path or
      "/var/run/#{PROJECT_NAME}/" .. system_service_name .. "/control/${MACHINE_NODE_ID}/"
    )

  local config_rocks =
  {
    tool = "deploy_rocks";
    "pk-tools.pk-ensure-runit-service-enabled";
    "pk-tools.pk-ensure-nginx-site-enabled";
    "pk-tools.pk-ensure-logrotate-enabled";
    "#{PROJECT_NAME}.tools.#{PROJECT_NAME}-execute-system-action";
    nginx_rock_name;
  }

  if logrotate_rock_name ~= nginx_rock_name then
    config_rocks[#config_rocks + 1] = logrotate_rock_name;
  end

  return
  {
    name = name;
    deployment_actions =
    {
      config_rocks;
      deploy_rocks;
    };
    post_deploy_actions = -- Warning: Order IS important here.
    {
      {
        tool = "ensure_dir_access_rights";
        dir = system_service_control_socket_path;
        owner_user = "www-data";
        owner_group = "www-data";
        mode = 770;
      };
      {
        tool = "ensure_file_access_rights";
        file = wsapi_log_file;
        owner_user = "www-data";
        owner_group = "www-data";
        mode = 600;
      };
      --
      {
        tool = "remote_exec";
        {
          'sudo', 'pk-ensure-runit-service-enabled',
           runit_service_name,
           '$(luarocks show --rock-dir ' .. runit_service_name
        .. ')/' .. runit_run_path
           ;
        };
      };
      --
      {
        tool = "remote_exec";
        {
          '#{PROJECT_NAME}-execute-system-action',
          system_service_name, system_service_node,
          'shutdown' -- Assuming runit will restart us at once
           ;
        };
      };
      --
      {
        tool = "remote_exec";
        {
          'sudo', 'pk-ensure-nginx-site-enabled',
          '$(luarocks show --rock-dir ' .. nginx_rock_name
           .. ')/' .. nginx_config_path
            ;
        };
      };
      --
      {
        tool = "remote_exec";
        {
          'sudo', 'pk-ensure-logrotate-enabled',
           '$(luarocks show --rock-dir ' .. logrotate_rock_name
           .. ')/' .. logrotate_config_path
            ;
        };
      };
    };
  }
end

roles =
{
  {
    name = "cluster-member";
    deployment_actions =
    {
      {
        -- Check if machine node ID is, in fact, the hostname.
        tool = "remote_exec"; -- TODO: Cache this!
        {
          -- TODO: Hack.
          "test", "${MACHINE_NODE_ID}", "=", "$(hostname)"
        }
      };
      {
        tool = "deploy_rocks";
        "#{PROJECT_NAME}.cluster-config.${CLUSTER_NAME}"; -- TODO: Do not list dependencies here, they are should be listed in rockspecs as needed
        "pk-tools.pk-lua-interpreter";
        "pk-tools.pk-call-lua-module";
      };
    };
  };
  --
  {
    name = "rocks-repo-localhost";
    deployment_actions =
    {
      -- Do nothing
    }
  };
  --
  {
    name = "rocks-repo-release";
    deployment_actions = -- TODO: BAD! rsync system/rocks/cluster-name repo instead!
    {
      {
        tool = "local_exec";
        {
          "pk-git-reset-branch-to-head",
          "deploy/#{DEPLOY_SERVER}", -- remotebranch
          "origin",                 -- destremote
          "HEAD",                   -- localbranch
          PROJECT_PATH              -- localroot
        };
      };
      --
      {
        tool = "local_exec";
        {
          "pk-git-update-host",
          "#{DEPLOY_SERVER}",        -- host
          "deploy/#{DEPLOY_SERVER}", -- localbranch
          "origin",              -- destremote
          "deploy/#{DEPLOY_SERVER}", -- remotebranch
          "/srv/#{PROJECT_NAME}-deployment"    -- remoteroot
        };
      };
    }
  };
  --
  static_nginx_role
  {
    name = "internal-config";
    rock_name = "#{PROJECT_NAME}.internal-config.${CLUSTER_NAME}";
    deploy_rocks = false; -- No extra rocks
    nginx_config_name = "cluster/${CLUSTER_NAME}/internal-config/nginx/#{PROJECT_NAME}-internal-config";
  };
  --
  static_nginx_role
  {
    name = "internal-config-deploy";
    rock_name = "#{PROJECT_NAME}.internal-config-deploy.${CLUSTER_NAME}";
    deploy_rocks = false; -- No extra rocks
    nginx_config_name = "cluster/${CLUSTER_NAME}/internal-config/nginx/#{PROJECT_NAME}-internal-config-deploy";
  };
  --
  static_nginx_role
  {
    name = "#{PROJECT_NAME}";
    rock_name = "#{PROJECT_NAME}.nginx.${CLUSTER_NAME}";
    deploy_rocks =
    {
      "#{PROJECT_NAME}.www.static"
    };
  };
  --
  wsapi_service_role
  {
    name = "#{PROJECT_NAME}-#{API_NAME}";
    wsapi =
    {
      service_name = "#{PROJECT_NAME}.#{API_NAME}";
      log_file = "/var/log/#{PROJECT_NAME}-#{API_NAME}-wsapi.log";
    };
    nginx =
    {
      rock_name = "#{PROJECT_NAME}.nginx.${CLUSTER_NAME}";
      config_path = "cluster/${CLUSTER_NAME}/nginx/#{PROJECT_NAME}";
    };
    logrotate =
    {
      rock_name = "#{PROJECT_NAME}.nginx.${CLUSTER_NAME}";
      config_path = "cluster/${CLUSTER_NAME}/logrotate/#{PROJECT_NAME}-#{API_NAME}";
    };
    runit =
    {
      service_name = "#{PROJECT_NAME}.#{API_NAME}";
      run_path = "www/#{API_NAME}/service/run";
    };
    system_service =
    {
      name = "#{API_NAME}";
      node = "${MACHINE_NODE_ID}";
    };
    deploy_rocks =
    {
      "#{PROJECT_NAME}.#{API_NAME}";
      "#{PROJECT_NAME}.lib"; -- TODO: This is a dependency, do not list it explicitly
    };
  };
  --
  plain_service_role
  {
    name = "#{PROJECT_NAME}-#{SERVICE_NAME}";
    log_file = "/var/log/#{PROJECT_NAME}-#{SERVICE_NAME}-service.log";
    logrotate =
    {
      rock_name = "#{PROJECT_NAME}.#{SERVICE_NAME}";
      config_path = "services/#{SERVICE_NAME}/logrotate/#{PROJECT_NAME}-#{SERVICE_NAME}";
    };
    runit =
    {
      service_name = "#{PROJECT_NAME}-#{SERVICE_NAME}";
      run_path = "services/#{SERVICE_NAME}/service/run";
    };
    system_service =
    {
      name = "#{PROJECT_NAME_UNDERLINE}_#{SERVICE_NAME_UNDERLINE}";
      node = "1";
    };
    deploy_rocks =
    {
      "#{PROJECT_NAME}.#{SERVICE_NAME}";
      "#{PROJECT_NAME}.lib"; -- TODO: Do not list dependencies here, move them to the rockspec
    };
  };
  --
  {
    name = "mysql-db"; -- TODO: stub mysql rock
    deployment_actions = { };
  };
  --
  {
    name = "redis-system"; -- TODO: stub redis rock
    deployment_actions = { };
  };
}
