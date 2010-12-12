--------------------------------------------------------------------------------
-- list-exports.lua: list import()-compliant exports
--------------------------------------------------------------------------------

dofile('tools-lib/init/require-developer.lua')
dofile('tools-lib/init/init.lua')

--------------------------------------------------------------------------------

local arguments,
      optional_arguments,
      method_arguments,
      eat_true
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments',
        'eat_true'
      }

local is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_table'
      }

local empty_table,
      timap,
      tkeys,
      tclone
      = import 'lua-nucleo/table.lua'
      {
        'empty_table',
        'timap',
        'tkeys',
        'tclone'
      }

local find_all_files
      = import 'lua-aplicado/filesystem.lua'
      {
        'find_all_files'
      }

local make_loggers
      = import 'pk-core/log.lua'
      {
        'make_loggers'
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

local CONFIG_SCHEMA_FILENAME,
      BASE_CONFIG_FILENAME,
      PROJECT_CONFIG_FILENAME
      = import 'tools-lib/config.lua'
      {
        'CONFIG_SCHEMA_FILENAME',
        'BASE_CONFIG_FILENAME',
        'PROJECT_CONFIG_FILENAME'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers("list-exports", "LEX")

--------------------------------------------------------------------------------

local Q = function(v) return ("%q"):format(tostring(v)) end

--------------------------------------------------------------------------------

local list = function(sources_dir, profile_filename, out_filename)
  sources_dir = sources_dir:gsub("/+$", "") -- Remove trailing slashes

  log(
      "listing all exports in ", sources_dir .. "/",
      "using profile", profile_filename,
      "dumping to", out_filename
    )

  local PROFILE = import(profile_filename) ()

  local export_map = setmetatable(
      -- TODO: Check format of PROFILE.raw
      PROFILE.raw and tclone(PROFILE.raw) or { },
      {
        __index = function(t, k)
          local v = { }
          t[k] = v
          return v
        end;
      }
    )

  local files = find_all_files(sources_dir, "%.lua$")
  table.sort(files)

  for i = 1, #files do
    local filename = files[i]

    if PROFILE.skip[filename] then
      log("skipping file", filename)
    else
      log("loading exports from file", filename)

      local exports = import (filename) ()
      for name, _ in pairs(exports) do
        local map = export_map[name]
        map[#map + 1] = filename
      end
    end
  end

  local sorted_map = { }
  for export, filenames in pairs(export_map) do
    if #filenames > 1 then
      log("found duplicates for", export, "in", filenames)
    end

    sorted_map[#sorted_map + 1] =
    {
      export = export;
      filenames = filenames;
    }
  end

  table.sort(
      sorted_map,
      function(lhs, rhs)
        return tostring(lhs.export) < tostring(rhs.export)
      end
    )

  do
    local file = assert(io.open(out_filename, "w"))

    file:write([[
--------------------------------------------------------------------------------
-- generated exports map for ]], sources_dir .. "/", [[

--------------------------------------------------------------------------------
-- WARNING! Do not change manually.
-- Generated by list-exports.lua
--------------------------------------------------------------------------------

return
{
]])

  for i = 1, #sorted_map do
    local export, filenames = sorted_map[i].export, sorted_map[i].filenames

    file:write([[
  ]], export, [[ = { ]], table.concat(timap(Q, filenames), ", "), [[ };
]])
  end

  file:write([[
}
]])

    file:close()
    file = nil
  end

  log("OK")
end

--------------------------------------------------------------------------------

local SCHEMA = load_tools_cli_data_schema(
    assert(loadfile(CONFIG_SCHEMA_FILENAME))
  )

local EXTRA_HELP, CONFIG, ARGS

--------------------------------------------------------------------------------

local ACTIONS = { }

ACTIONS.help = function()
  print_tools_cli_config_usage(EXTRA_HELP, SCHEMA)
end

ACTIONS.list_all = function()
  local exports = CONFIG.common.exports

  local sources = freeform_table_value(exports.sources) -- Hack. Use iterator
  for i = 1, #sources do
    local source = sources[i]

    list(
        source.sources_dir,
        exports.profiles_dir .. source.profile_filename,
        exports.exports_dir .. source.out_filename
      )
  end
end

--------------------------------------------------------------------------------

EXTRA_HELP = [[

Usage:

  ]] .. arg[0] .. [[ --root=<PROJECT_PATH> <action> [options]

Actions:

  * ]] .. table.concat(tkeys(ACTIONS), "\n  * ") .. [[

]]

--------------------------------------------------------------------------------

CONFIG, ARGS = assert(load_tools_cli_config(
    function(args)
      return
      {
        PROJECT_PATH = args["--root"];
        list_exports = { action = { name = args[1] or args["--action"]; }; };
      }
    end,
    EXTRA_HELP,
    SCHEMA,
    BASE_CONFIG_FILENAME,
    PROJECT_CONFIG_FILENAME,
    ...
  ))

--------------------------------------------------------------------------------

ACTIONS[CONFIG.list_exports.action.name]()
