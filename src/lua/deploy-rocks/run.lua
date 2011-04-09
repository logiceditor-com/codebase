local log, dbg, spam, log_error
      = import 'pk-core/log.lua' { 'make_loggers' } (
          "deploy-rocks-run", "DRR"
        )

--------------------------------------------------------------------------------

local pcall, assert, error, select, next = pcall, assert, error, select, next

--------------------------------------------------------------------------------

local tpretty
      = import 'lua-nucleo/tpretty.lua'
      {
        'tpretty'
      }

local tstr
      = import 'lua-nucleo/tstr.lua'
      {
        'tstr'
      }

local timapofrecords,
      twithdefaults
      = import 'lua-nucleo/table-utils.lua'
      {
        'timapofrecords',
        'twithdefaults'
      }

local write_file,
      read_file,
      find_all_files,
      does_file_exist
      = import 'lua-aplicado/filesystem.lua'
      {
        'write_file',
        'read_file',
        'find_all_files',
        'does_file_exist'
      }

local load_project_manifest
      = import 'pk-tools/project_manifest.lua'
      {
        'load_project_manifest'
      }

local load_tools_cli_data_schema,
      load_tools_cli_config,
      print_tools_cli_config_usage,
      freeform_table_value
      = import 'pk-core/tools_cli_config.lua'
      {
        'load_tools_cli_data_schema',
        'load_tools_cli_config',
        'print_tools_cli_config_usage',
        'freeform_table_value'
      }

local deploy_rocks_from_versions_filename,
      deploy_rocks_from_code,
      writeln_flush,
      write_flush,
      ask_user
      = import 'deploy-rocks/deploy_rocks.lua'
      {
        'deploy_rocks_from_versions_filename',
        'deploy_rocks_from_code',
        'writeln_flush',
        'write_flush',
        'ask_user'
      }

--------------------------------------------------------------------------------

local create_config_schema
      = import 'deploy-rocks/project-config/schema.lua'
      {
        'create_config_schema'
      }

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config-related constants
--

local TOOL_NAME = "deploy_rocks"

local EXTRA_HELP = [[

deploy-rocks: deployment tool
--TODO: insert some description here and clean up

Usage:

    deploy-rocks <action> <cluster> [<version_file>] [<machine_name>] [options]

Actions:

    deploy_from_code               If 'deploy_from_code' is used <version_file>
                                   and <machine_name> must not be defined.

    deploy_from_versions_file      If 'deploy_from_versions_file' is used
                                   <version_file> must be defined.

    partial_deploy_from_versions_file
                                   If 'partial_deploy_from_versions_file' is
                                   used both <version_file> and <machine_name>
                                   must be defined.

Options:

    --debug                        Allow not clean git repositories

    --dry-run                      Go through algorythm but do nothing

Example:

     deploy-rocks deploy_from_code localhost --debug

]]

local CONFIG_SCHEMA = create_config_schema()

local CONFIG, ARGS

local ACTIONS = { }

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Auxiliary actions
--

ACTIONS.help = function()
  print_tools_cli_config_usage(EXTRA_HELP, CONFIG_SCHEMA)
end

ACTIONS.check_config = function()
  write_flush("config OK\n")
end

ACTIONS.dump_config = function()
  write_flush(tpretty(freeform_table_value(CONFIG), "  ", 80), "\n")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Main deploy actions
--

ACTIONS.deploy_from_code = function()
  local param = CONFIG.deploy_rocks.action.param

  if not param.dry_run then
    if ask_user(
        "Do you want to deploy code to `" .. param.cluster_name .. "'?",
        { "y", "n" },
        "n"
      ) ~= "y"
    then
      error("Aborted.")
    end
  end

  local manifest = load_project_manifest(
      param.manifest_path,
      CONFIG.PROJECT_PATH,
      param.cluster_name
    )

  if param.debug then
    writeln_flush("-!!-> DEBUG MODE ON")
    manifest.debug_mode = true -- TODO: HACK! Store state elsewhere!
  end

  if param.dry_run then
    writeln_flush("-!!-> DRY RUN BEGIN <----")
  end

  deploy_rocks_from_code(
      manifest,
      param.cluster_name,
      param.dry_run
    )

  writeln_flush("----> OK")

  if param.dry_run then
    writeln_flush("-!!-> DRY RUN END <----")
    return
  end
end

--------------------------------------------------------------------------------

ACTIONS.deploy_from_versions_file = function()
  local param = CONFIG.deploy_rocks.action.param

  if not param.dry_run then
    if ask_user(
        "Do you want to deploy code to `" .. param.cluster_name .. "'"
     .. " from version file `" .. param.version_filename .. "'?",
        { "y", "n" },
        "n"
      ) ~= "y"
    then
      error("Aborted.")
    end
  end

  -- TODO: Should we copy versions file to get a new timestamp?

  local manifest = load_project_manifest(
      param.manifest_path,
      CONFIG.PROJECT_PATH,
      param.cluster_name
    )

  if param.debug then
    writeln_flush("-!!-> DEBUG MODE ON")
    manifest.debug_mode = true -- TODO: HACK! Store state elsewhere!
  end

  if param.dry_run then
    writeln_flush("-!!-> DRY RUN BEGIN <----")
  end

  deploy_rocks_from_versions_filename(
      manifest,
      param.cluster_name,
      param.version_filename,
      true,
      param.dry_run
    )

  writeln_flush("----> OK")

  if param.dry_run then
    writeln_flush("-!!-> DRY RUN END <----")
    return
  end
end

--------------------------------------------------------------------------------

ACTIONS.partial_deploy_from_versions_file = function()
  local param = CONFIG.deploy_rocks.action.param

  if not param.dry_run then
    if ask_user(
        "(Not recommended!) Do you want to deploy code to cluster `"
     .. param.cluster_name .. "' ONE machine `" .. param.machine_name .. "' "
     .. "from version file `" .. param.version_filename .. "'?"
     .. " (WARNING: Ensure you pushed changes to cluster's LR repository.)",
        { "y", "n" },
        "n"
      ) ~= "y"
    then
      error("Aborted.")
    end
  end

  -- TODO: Should we copy versions file to get a new timestamp?

  local manifest = load_project_manifest(
      param.manifest_path,
      CONFIG.PROJECT_PATH,
      param.cluster_name
    )

  if param.debug then
    writeln_flush("-!!-> DEBUG MODE ON")
    manifest.debug_mode = true -- TODO: HACK! Store state elsewhere!
  end

  if param.dry_run then
    writeln_flush("-!!-> DRY RUN BEGIN <----")
  end

  -- TODO: HACK
  do
    local clusters_by_name = timapofrecords(manifest.clusters, "name")
    local machines =
      assert(clusters_by_name[param.cluster_name], "cluster not found").machines
    local found = false
    for i = 1, #machines do
      local machine = machines[i]
      if machine.name ~= param.machine_name then
        writeln_flush("----> Ignoring machine `", machine.name, "'")
        machines[i] = nil
      else
        found = true
        writeln_flush("----> Deploying to machine `", machine.name, "'")
      end
    end

    assert(found == true, "machine not found")
  end

  deploy_rocks_from_versions_filename(
      manifest,
      param.cluster_name,
      param.version_filename,
      false,
      param.dry_run
    )

  writeln_flush("----> OK")

  if param.dry_run then
    writeln_flush("-!!-> DRY RUN END <----")
    return
  end
end

--------------------------------------------------------------------------------

-- TODO: AUTOMATE THIRD-PARTY MODULE UPDATES! (when our modules are not changed)
-- TODO: Check out proper branches in each repo before analysis.
-- TODO: Do with lock file
-- TODO: ALSO LOCK REMOTELY!
-- TODO: Handle rock REMOVAL!
local run = function(...)
  local CODE_ROOT = assert(select(1, ...), "code root missing")

  ------------------------------------------------------------------------------
  -- Handle command-line options
  --
  CONFIG, ARGS = assert(load_tools_cli_config(
      function(args) -- Parse actions
        local param = { }

        local action_name   = args[2] or "help"

        param.manifest_path = args[1]
        param.cluster_name  = args[3]
        param.debug         = args["--debug"]
        param.dry_run       = args["--dry-run"]

        if action_name     == "deploy_from_versions_file" then
          param.version_filename = args[4]
        elseif action_name == "partial_deploy_from_versions_file" then
          param.version_filename = args[4]
          param.machine_name     = args[5]
        end

        local config =
        {
          PROJECT_PATH = CODE_ROOT;
          [TOOL_NAME] = {
            action = {
              name = action_name;
              param = param;
            };
          }
        }

        return config
      end,
      EXTRA_HELP,
      CONFIG_SCHEMA,
      nil, -- Specify primary config file with --base-config cli option
      nil, -- No secondary config file
      select(2, ...) -- First argument is CODE_ROOT, eating it
    ))

  ------------------------------------------------------------------------------
  -- Run the action that user requested
  --
  ACTIONS[CONFIG[TOOL_NAME].action.name]()
end

--------------------------------------------------------------------------------

return
{
  run = run;
}
