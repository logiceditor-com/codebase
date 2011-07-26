--------------------------------------------------------------------------------
-- test.lua: test runner
--------------------------------------------------------------------------------
-- TODO: Consider promoting this to pk-tools
--------------------------------------------------------------------------------

-- TODO: Fix module dependencies.
--       Note that coxpcal makes no sense under LJ2,
--       and should not be used in production.

declare 'copcall'
declare 'coxpcall'
require 'coxpcall'

--------------------------------------------------------------------------------

local log, dbg, spam, log_error
      = import 'pk-core/log.lua' { 'make_loggers' } (
          "pk-logiceditor/test", "PLT"
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

local escape_lua_pattern
      = import 'lua-nucleo/string.lua'
      {
        'escape_lua_pattern'
      }

local tifilter
      = import 'lua-nucleo/table-utils.lua'
      {
        'tifilter'
      }

local run_tests
      = import 'lua-nucleo/suite.lua'
      {
        'run_tests'
      }

local find_all_files,
      get_filename_from_path
      = import 'lua-aplicado/filesystem.lua'
      {
        'find_all_files',
        'get_filename_from_path'
      }

local load_tools_cli_data_schema
      = import 'pk-core/tools_cli_config.lua'
      {
        'load_tools_cli_data_schema'
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

--------------------------------------------------------------------------------

local run_tests_in_path = function(
    test_cases_path,
    test_case_filename_pattern,
    test_case_filter,
    randomseed,
    strict,
    quick
  )
  arguments(
      "string", test_cases_path,
      "string", test_case_filename_pattern,
      "string", test_case_filter,
      "number", randomseed,
      "boolean", strict,
      "boolean", quick
    )

  local test_files = find_all_files(test_cases_path, test_case_filename_pattern)
  table.sort(test_files)

  local test_case_filter_raw = "^" .. escape_lua_pattern(test_case_filter)

  local filtered = tifilter(
      function(path)
        return get_filename_from_path(path):match(test_case_filter_raw)
            or path:match(test_case_filter)
      end,
      test_files
    )

  if #filtered < 1 then
    error("no tests to match filter string `" .. test_case_filter .. "'")
  end

  run_tests(
      filtered,
      {
        strict_mode = strict;
        seed_value = randomseed;
        -- TODO: Support quick!
      }
    )
end

--------------------------------------------------------------------------------

local create_config_schema = function()
  return load_tools_cli_data_schema(function()
    cfg:root
    {
      cfg:node "test"
      {
        cfg:existing_path "test_cases_path";
        cfg:string "test_case_filename_pattern" { default = ".*%.lua$" };

        cfg:string "test_case_filter";

        cfg:integer "randomseed" { default = 123456 };

        cfg:boolean "strict" { default = false };
        cfg:boolean "quick" { default = false };
      };
    }
  end)
end

--------------------------------------------------------------------------------

local EXTRA_HELP = [[

test: test runner

Usage:

    ./test.sh [test-case-filter] [options]

Examples:

    ./test.sh "0099"
    ./test.sh "^subdir/.*string.*" --quick

Options:

    --strict            Run tests in strict mode.
                        Default: run tests in relaxed mode.
    --quick             Don't run slow tests.
                        Default: run slow tests.
    --randomseed=<int>  Use given value as randomseed.
                        Default: `123456'.
]]

local TOOL_NAME = "test"

local CONFIG_SCHEMA = create_config_schema()

local CONFIG, ARGS

--------------------------------------------------------------------------------

local run = function(...)
  -- WARNING: Custom tool logic. Take care when copy-pasting.

  CONFIG, ARGS = load_tools_cli_config(
      function(args) -- Parse actions
        local param = { }

        param.test_cases_path = args["--test-cases-path"]
        param.test_case_filter = args[1] or ".*"

        param.strict = not not args["--strict"]
        param.quick = not not args["--quick"]
        param.randomseed = args["--randomseed"]

        return
        {
          PROJECT_PATH = args["--root"];
          [TOOL_NAME] = param;
        }
      end,
      EXTRA_HELP,
      CONFIG_SCHEMA,
      nil, -- Specify primary config file with --base-config cli option
      nil, -- No secondary config file
      ...
    )

  if CONFIG == nil then
    local err = ARGS

    print_tools_cli_config_usage(EXTRA_HELP, CONFIG_SCHEMA)

    io.stderr:write("Error in tool configuration:\n", err, "\n\n")
    io.stderr:flush()

    os.exit(1)
  end

  run_tests_in_path(
      CONFIG[TOOL_NAME].test_cases_path,
      CONFIG[TOOL_NAME].test_case_filename_pattern,
      CONFIG[TOOL_NAME].test_case_filter,
      CONFIG[TOOL_NAME].randomseed,
      CONFIG[TOOL_NAME].strict,
      CONFIG[TOOL_NAME].quick
    )
end

--------------------------------------------------------------------------------

return
{
  run = run;
}
