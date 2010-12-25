--------------------------------------------------------------------------------
-- tools_cli_config.lua: tools CLI/configuration handler
--------------------------------------------------------------------------------
-- Sandbox warning: alias all globals!
--------------------------------------------------------------------------------

local lfs = require 'lfs'

--------------------------------------------------------------------------------

local tostring, type, assert, select, loadfile, error
    = tostring, type, assert, select, loadfile, error

local os = os
local io = io
local table = table

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

local is_function
      = import 'lua-nucleo/type.lua'
      {
        'is_function'
      }

local empty_table,
      tkeys,
      tclone,
      twithdefaults,
      treadonly,
      tidentityset
      = import 'lua-nucleo/table-utils.lua'
      {
        'empty_table',
        'tkeys',
        'tclone',
        'twithdefaults',
        'treadonly',
        'tidentityset'
      }

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

local invariant
      = import 'lua-nucleo/functional.lua'
      {
        'invariant'
      }

local unique_object
      = import 'lua-nucleo/misc.lua'
      {
        'unique_object'
      }

local do_in_environment,
      dostring_in_environment,
      make_config_environment
      = import 'lua-nucleo/sandbox.lua'
      {
        'do_in_environment',
        'dostring_in_environment',
        'make_config_environment'
      }
local load_all_files,
      find_all_files
      = import 'lua-aplicado/filesystem.lua'
      {
        'load_all_files',
        'find_all_files'
      }

local make_loggers
      = import 'pk-core/log.lua'
      {
        'make_loggers'
      }

local load_data_walkers,
      load_data_schema
      = import 'pk-core/walk_data_with_schema.lua'
      {
        'load_data_walkers',
        'load_data_schema'
      }

local dump_nodes
      = import 'pk-core/dump_nodes.lua'
      {
        'dump_nodes'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers("pk-core/tools_cli", "TCL")

--------------------------------------------------------------------------------

local get_tools_cli_data_walkers
do
  -- TODO: Heavy. Initialize on-demand?
  local walkers = load_data_walkers(function()

    --
    -- Use these types to define your config file schema.
    --

    types:up "cfg:boolean" (function(self, info, value)
      self:ensure_equals("unexpected type", type(value), "boolean")
    end)

    types:up "cfg:number" (function(self, info, value)
      self:ensure_equals("unexpected type", type(value), "number")
    end)

    types:up "cfg:integer" (function(self, info, value)
      local _ =
        self:ensure_equals("unexpected type", type(value), "number"):good()
        and self:ensure("must be integer", value % 1 == 0, value)
    end)

    types:up "cfg:positive_integer" (function(self, info, value)
      local _ =
        self:ensure_equals("unexpected type", type(value), "number"):good()
        and self:ensure("must be integer", value % 1 == 0, value):good()
        and self:ensure("must be > 0", value > 0, value)
    end)

    types:up "cfg:port" (function(self, info, value)
      local _ =
        self:ensure_equals("unexpected type", type(value), "number"):good()
        and self:ensure(
            "port value must be integer", value % 1 == 0, value
          ):good()
        and self:ensure("port value too small", value >= 1, value):good()
        and self:ensure("port value too large", value <= 65535, value)
    end)

    types:up "cfg:string" (function(self, info, value)
      self:ensure_equals("unexpected type", type(value), "string")
    end)

    types:up "cfg:optional_string" (function(self, info, value)
      self:ensure(
          "unexpected type",
          value == nil or type(value) == "string",
          type(value)
        )
    end)

    types:up "cfg:non_empty_string" (function(self, info, value)
      local _ =
        self:ensure_equals("unexpected type", type(value), "string"):good()
        and self:ensure("string must not be empty", value ~= "")
    end)

    types:up "cfg:host" (function(self, info, value)
      local _ =
        self:ensure_equals("unexpected type", type(value), "string"):good()
        and self:ensure("host string must not be empty", value ~= "")
    end)

    types:up "cfg:path" (function(self, info, value)
      local _ =
        self:ensure_equals("unexpected type", type(value), "string"):good()
        and self:ensure("path string must not be empty", value ~= "")
    end)

    types:up "cfg:optional_path" (function(self, info, value)
      if value ~= nil then
        local _ =
          self:ensure_equals("unexpected type", type(value), "string"):good()
          and self:ensure("path string must not be empty", value ~= "")
      end
    end)

    types:up "cfg:url" (function(self, info, value)
      local _ =
        self:ensure_equals("unexpected type", type(value), "string"):good()
        and self:ensure("url string must not be empty", value ~= "")
    end)

    types:up "cfg:existing_path" (function(self, info, value)
      local _ =
        self:ensure_equals("unexpected type", type(value), "string"):good()
        and self:ensure("path string must not be empty", value ~= ""):good()
        and self:ensure("path must exist", lfs.attributes(value))
    end)

    types:up "cfg:enum_value" (function(self, info, value)
      if not info.values_set then
        info.values_set = tidentityset(
            assert(info.values, "bad schema: missing enum values")
          )
      end
      if info.values_set[value] == nil then
        self:fail(
            "unexpected value `" .. tostring(value) .. "',"
         .. " expected one of { "
         .. table.concat(tkeys(info.values_set), " | ")
         .. " }"
          )
      end
    end)

    types:up "cfg:freeform_table" (function(self, info, value)
      self:ensure_equals("unexpected type", type(value), "table")
    end)

    types:variant "cfg:variant"

    types:ilist "cfg:ilist"

    types:ilist "cfg:non_empty_ilist" (function(self, info, value)
      self:ensure("ilist must not be empty", #value > 0)
    end)

    types:node "cfg:node"

    types:root "cfg:root"

    --
    -- Technical details below
    --

    local ensure_equals = function(self, msg, actual, expected)
      if actual ~= expected then
        self.checker_:fail(
            msg .. ":"
         .. " actual: " .. tostring(actual)
         .. " expected: " .. tostring(expected)
          )
      end
      return self
    end

    local ensure = function(self, ...)
      self.checker_:ensure(...)
      return self
    end

    local fail = function(self, msg)
      self.checker_:fail(msg)
      return self
    end

    local good = function(self)
      return self.checker_:good()
    end

    types:factory (function(checker)

      return
      {
        ensure_equals = ensure_equals;
        ensure = ensure;
        fail = fail;
        good = good;
        --
        checker_ = checker;
      }
    end)

  end)

  -- TODO: Need write-protection.
  get_tools_cli_data_walkers = invariant(walkers)
end

--------------------------------------------------------------------------------

local load_tools_cli_data_schema
do
  local extra_env =
  {
    import = import; -- Trusted sandbox
  }

  load_tools_cli_data_schema = function(schema_chunk)
    arguments("function", schema_chunk)
    return load_data_schema(schema_chunk, extra_env, { "cfg" })
  end
end

--------------------------------------------------------------------------------

local load_tools_cli_data
do
  load_tools_cli_data = function(schema, data)
    if is_function(schema) then
      schema = load_tools_cli_data_schema(schema)
    end

    arguments(
        "table", schema,
        "table", data
      )

    local checker = get_tools_cli_data_walkers():walk_data_with_schema(
        schema,
        data
      ):get_checker()

    if not checker:good() then
      return checker:result()
    end

    return data
  end
end

--------------------------------------------------------------------------------

local parse_tools_cli_arguments = function(canonicalization_map, ...)
  arguments("table", canonicalization_map)

  local n = select("#", ...)

  local args = { }

  local i = 1
  while i <= n do
    local arg = select(i, ...)
    if arg:match("^%-%-[^%-=].-=.*$") then
      -- TODO: Optimize. Do not do double matching
      local name, value = arg:match("^(%-%-[^%-=].-)=(.*)$")
      assert(name)
      assert(value)
      args[canonicalization_map[name] or name] = value
    elseif arg:match("^%-[^%-].*$") then
      local name = arg

      i = i + 1
      local value = select(i, ...)

      args[canonicalization_map[name] or name] = value
    else
      local name = canonicalization_map[arg] or arg
      args[#args + 1] = name
      args[name] = true
    end
    i = i + 1
  end

  return args
end

--------------------------------------------------------------------------------

local print_tools_cli_config_usage = function(extra_help, schema)
  arguments(
      "string", extra_help,
      "table", schema
    )

  io.stdout:write(extra_help)

  io.stdout:write([[

Options:

    --help                     Print this text
    --dump-format              Print config file format
    --root=<path>              Absolute path to project
    --param=<lua-table>        Add data from lua-table to config
    --config=<filename>        Override config filename
    --no-config                Do not load project config file
    --base-config=<filename>   Override base config filename
    --no-base-config           Do not load base project config file

]])

  io.stdout:flush()

end

local print_format = function(schema)
  arguments(
      "table", schema
    )

  io.stdout:write([[

Config format:

]])

  -- TODO: Output should be more Lua-like!
  dump_nodes(
      schema, -- dump schema
      "-",    -- to stdout
      "id",   -- tag field
      "name", -- name field
      true,   -- with indent
      true    -- with names
    )

  io.stdout:flush()

end

--------------------------------------------------------------------------------

local raw_config_table_key = unique_object()

local raw_config_table_callback = function(t)
  return t
end

-- TODO: Hack. Protect only data defined in schema!
local freeform_table_value = function(t)
  return tclone(t[raw_config_table_key]())
end

-- TODO: Too rigid. Must be more flexible.
local load_tools_cli_config
do
  local callbacks = { [raw_config_table_key] = raw_config_table_callback }

  load_tools_cli_config = function(
      arg_to_param_mapper,
      extra_help,
      schema,
      base_config_filename,
      project_config_filename,
      ... -- Pass cli arguments here
    )
    arguments(
        "table", schema
      )

    optional_arguments(
        "string", base_config_filename,
        "string", project_config_filename
      )

    local args = parse_tools_cli_arguments(
        empty_table,
        ...
      )

    local help_printed = false
    if args["--help"] then
      print_tools_cli_config_usage(extra_help, schema)
      help_printed = true
    end

    if args["--dump-format"] then
      print_format(schema)
      help_printed = true
    end

    if help_printed then
      return os.exit(1) -- TODO: This is caller's business!
    end

    -- Note tclone()
    local args_config = arg_to_param_mapper(tclone(args))

    -- Hack. Implicitly forcing config schema to have PROJECT_PATH key
    -- Better to do this explicitly somehow?
    local PROJECT_PATH = assert(args_config.PROJECT_PATH, "missing PROJECT_PATH")

    local project_config_filename = args["--config"] or project_config_filename
    local base_config_filename = args["--base-config"] or base_config_filename

    local extra_param = make_config_environment({ PROJECT_PATH = PROJECT_PATH })
    if args["--param"] then
      assert(dostring_in_environment(args["--param"], extra_param, "@--param"))
    end

    -- TODO: Hack? Only base and project configs are allowed import()
    -- TODO: Let user to specify environment explicitly instead.
    local base_config = make_config_environment(
        {
          PROJECT_PATH = PROJECT_PATH;
          import = import;
        }
      )
    if not args["--no-base-config"] and base_config_filename then
      --[[
      io.stdout:write(
          "--> loading base config file ", base_config_filename, "\n"
        )
      io.stdout:flush()
      --]]

      local attr = assert(lfs.attributes(base_config_filename))
      if attr.mode == "directory" then
        local base_config_files = find_all_files(base_config_filename, ".")
        local base_config_chunks = load_all_files(base_config_filename, ".")
        for i = 1, #base_config_chunks do
          assert(do_in_environment(base_config_chunks[i], base_config))
        end
      else
        local base_config_chunk = assert(loadfile(base_config_filename))
        assert(do_in_environment(base_config_chunk, base_config))
      end
    end

    if base_config.import == import then
      base_config.import = nil -- TODO: Hack. Use metatables instead
    end

    local config = make_config_environment(
        {
          PROJECT_PATH = PROJECT_PATH;
          import = import;
        }
      )
    if not args["--no-config"] and project_config_filename then
      --[[
      io.stdout:write(
          "--> loading project config file ", project_config_filename, "\n"
        )
      io.stdout:flush()
      --]]
      local attr = assert(lfs.attributes(project_config_filename))
      if attr.mode == "directory" then
        local project_config_files = find_all_files(project_config_filename, ".")
        local project_config_chunks = load_all_files(project_config_filename, ".")
        for i = 1, #project_config_chunks do
          assert(do_in_environment(project_config_chunks[i], config))
        end
      else
        local project_config_chunk = assert(loadfile(project_config_filename))
        assert(do_in_environment(project_config_chunk, config))
      end
    end

    if config.import == import then
      config.import = nil -- TODO: Hack. Use metatables instead
    end

    -- Hack. Doing tclone() to remove __metatabled metatable
    config = twithdefaults(
        args_config,
        twithdefaults(
            tclone(extra_param),
            twithdefaults(
                tclone(config),
                tclone(base_config)
              )
          )
      )

    --[[
    io.stdout:write("--> validating cumulative config\n")
    io.stdout:flush()
    --]]

    local err

    config, err = load_tools_cli_data(schema, config)
    if config == nil then
      return nil, err
    end

    return treadonly(config, callbacks, tstr), args
  end
end

--------------------------------------------------------------------------------

return
{
  load_tools_cli_data_schema = load_tools_cli_data_schema;
  load_tools_cli_config = load_tools_cli_config;
  print_tools_cli_config_usage = print_tools_cli_config_usage;
  freeform_table_value = freeform_table_value;
  -- Export more as needed.
}
