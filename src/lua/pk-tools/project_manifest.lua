--------------------------------------------------------------------------------
-- project_manifest.lua: tools to work with project manifests
--------------------------------------------------------------------------------
-- TODO: Upgrade deploy-rocks to use this
--------------------------------------------------------------------------------

local log, dbg, spam, log_error
      = import 'pk-core/log.lua' { 'make_loggers' } (
          "deploy-rocks", "DRO"
        )

--------------------------------------------------------------------------------

local arguments,
      optional_arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments'
      }

local do_in_environment
      = import 'lua-nucleo/sandbox.lua'
      {
        'do_in_environment'
      }

local read_file,
      find_all_files
      = import 'lua-aplicado/filesystem.lua'
      {
        'read_file',
        'find_all_files'
      }

local fill_curly_placeholders
      = import 'lua-nucleo/string.lua'
      {
        'fill_curly_placeholders'
      }

--------------------------------------------------------------------------------

-- TODO: Generalize to lua-aplicado
local load_files_with_curly_placeholders = function(path, context)
  arguments(
      "string", path,
      "table", context
    )

  local env =
  {
    import = import; -- This is a trusted sandbox
    assert = assert;
  }

  local filenames = find_all_files(path, ".*%.lua$")
  table.sort(filenames)

  for i = 1, #filenames do
    local filename = filenames[i]

    local str = assert(read_file(filename))

    str = fill_curly_placeholders(str, context)

    local chunk = assert(loadstring(str, "=" .. filename))

    local ok, result = assert(do_in_environment(chunk, env))
    assert(result == nil)
  end

  -- Hack. Use metatable instead.
  if env.import == import then
    env.import = nil
  end

  if env.assert == assert then
    env.assert = nil
  end

  return env
end

--------------------------------------------------------------------------------

-- TODO: Add validation, reuse tools_cli_config stuff.
local load_project_manifest
do
  local mt =
  {
    __index = function(t, k)
      error(
          "unknown placeholder: ${" .. (tostring(k) or "(not-a-string)") .. "}"
        )
    end;
  }

  load_project_manifest = function(
        manifest_path,
        project_path,
        cluster_name
      )
    arguments(
        "string", manifest_path,
        "string", project_path,
        "string", cluster_name
      )

    return load_files_with_curly_placeholders(
        manifest_path,
        setmetatable(
            {
              PROJECT_PATH = project_path;
              CLUSTER_NAME = cluster_name;
            },
            mt
          )
      )
  end
end

--------------------------------------------------------------------------------

return
{
  load_files_with_curly_placeholders = load_files_with_curly_placeholders;
  load_project_manifest = load_project_manifest;
}
