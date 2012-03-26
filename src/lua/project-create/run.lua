--------------------------------------------------------------------------------
-- run.lua: project-create runner
-- This file is a part of pk-project-tools library
-- Copyright (c) Alexander Gladysh <ag@logiceditor.com>
-- Copyright (c) Dmitry Potapov <dp@logiceditor.com>
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

local loadfile, loadstring = loadfile, loadstring

-- Create module loggers
local log, dbg, spam, log_error
      = import 'pk-core/log.lua' { 'make_loggers' } (
          "project-create", "PRC"
        )

--------------------------------------------------------------------------------

local table_sort = table.sort

--------------------------------------------------------------------------------

local lfs = require 'lfs'

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

local is_table,
      is_function,
      is_string,
      is_number
      = import 'lua-nucleo/type.lua'
      {
        'is_table',
        'is_function',
        'is_string',
        'is_number'
      }

local tgetpath,
      tclone,
      twithdefaults,
      tset,
      tiflip
      = import 'lua-nucleo/table-utils.lua'
      {
        'tgetpath',
        'tclone',
        'twithdefaults',
        'tset',
        'tiflip'
      }
local ordered_pairs
      = import 'lua-nucleo/tdeepequals.lua'
      {
        'ordered_pairs'
      }
local load_all_files,
      write_file,
      read_file,
      create_path_to_file,
      find_all_files,
      is_directory,
      does_file_exist,
      write_file,
      read_file,
      create_path_to_file
      = import 'lua-aplicado/filesystem.lua'
      {
        'load_all_files',
        'write_file',
        'read_file',
        'create_path_to_file',
        'find_all_files',
        'is_directory',
        'does_file_exist',
        'write_file',
        'read_file',
        'create_path_to_file'
      }

local luarocks_show_rock_dir
      = import 'lua-aplicado/shell/luarocks.lua'
      {
        'luarocks_show_rock_dir'
      }

local copy_file_with_flag,
      copy_file,
      remove_file,
      remove_recursively
      = import 'lua-aplicado/shell/filesystem.lua'
      {
        'copy_file_with_flag',
        'copy_file',
        'remove_file',
        'remove_recursively'
      }

local shell_read,
      shell_exec
      = import 'lua-aplicado/shell.lua'
      {
        'shell_read',
        'shell_exec'
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

local load_project_manifest
      = import 'pk-tools/project_manifest.lua'
      {
        'load_project_manifest'
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

local copy_file_force,
      check_path_ignored,
      get_dictionary_pattern,
      break_path,
      add_to_directory_structure,
      process_dictionary_recursively,
      get_replacement_pattern,
      unify_manifest_dictionary,
      create_directory_structure,
      fill_placeholders
      = import 'pk-project-create/common_functions.lua'
      {
        'copy_file_force',
        'check_path_ignored',
        'get_dictionary_pattern',
        'break_path',
        'add_to_directory_structure',
        'process_dictionary_recursively',
        'get_replacement_pattern',
        'unify_manifest_dictionary',
        'create_directory_structure',
      }

local do_replicate_data
      = import 'pk-project-create/replicate_data.lua'
      {
        'do_replicate_data'
      }

local copy_files_from_templates,
      clean_up_replicate_data_recursively,
      clean_up_generated_data_recursively,
      fill_placeholders
      = import 'pk-project-create/copy_files.lua'
      {
        'copy_files_from_templates',
        'clean_up_replicate_data_recursively',
        'clean_up_generated_data_recursively',
        'fill_placeholders'
      }

--------------------------------------------------------------------------------

local create_config_schema
      = import 'project-create/project-config/schema.lua'
      {
        'create_config_schema'
      }

--------------------------------------------------------------------------------

local TOOL_NAME = "project_create"
local CONFIG, ARGS

--------------------------------------------------------------------------------

local create_project
do
  ------------------------------------------------------------------------------
  local DEBUG_print = function(...)
    if CONFIG[TOOL_NAME].debug then
      print(...)
    end
  end

  ------------------------------------------------------------------------------

  local process_ignored_paths = function(metamanifest)
    local ignored = tset(metamanifest.ignore_paths)
    for ignore, _ in ordered_pairs(ignored) do
      for k, v in ordered_pairs(metamanifest.dictionary) do
        if is_table(v) then
          for j = 1, #v do
            if not ignored[ignore:gsub(k:gsub("%p", "%%%1"), v[j])] then
              ignored[ignore:gsub(k:gsub("%p", "%%%1"), v[j])] = true
              ignored[ignore] = nil
            end
          end
        elseif v == false then
          if not ignored[ignore:gsub(k:gsub("%p", "%%%1"), "")] then
            ignored[ignore] = nil
          end
        elseif v == true then -- TODO: HACK!
          -- ignore
        else
          if not ignored[ignore:gsub(k:gsub("%p", "%%%1"), v)] then
            ignored[ignore:gsub(k:gsub("%p", "%%%1"), v)] = true
            ignored[ignore] = nil
          end
        end
      end
    end
    metamanifest.ignore_paths = ignored
    DEBUG_print("\27[32mmetamanifest.ignored\27[0m: \n " .. tpretty(metamanifest.ignore_paths))
    return metamanifest
  end

  ------------------------------------------------------------------------------

  create_project = function(
      metamanifest_path,
      project_path,
      root_template_name,
      root_template_paths
    )
    arguments(
        "string", metamanifest_path,
        "string", project_path,
        "string", root_template_name,
        "table", root_template_paths
      )

    log("Loading metamanifest")

    -- TODO: HACK? how to get path to this?
    local defaults_path =
      assert(luarocks_show_rock_dir("pk-project-tools.pk-project-create"))
    defaults_path =
      defaults_path:sub(1, -1) .. "/src/lua/project-create/metamanifest"

    -- template_path
    local metamanifest_defaults = load_project_manifest(defaults_path, "", "")
    local metamanifest_project = load_project_manifest(
        metamanifest_path,
        project_path,
        ""
      )
    metamanifest_defaults.dictionary = unify_manifest_dictionary(
        metamanifest_defaults.dictionary
      )

    metamanifest_project.dictionary = unify_manifest_dictionary(
        metamanifest_project.dictionary
      )
    if metamanifest_defaults.version ~= metamanifest_project.version then
      DEBUG_print(
          "\27[31mWrong metamanifest version:\27[0m",
          "\nexpected:", metamanifest_defaults.version,
          "\ngot:", metamanifest_project.version
        )
      error("Wrong metamanifest version")
    end

    local metamanifest = twithdefaults(metamanifest_project, metamanifest_defaults)
    metamanifest.project_path = project_path
    DEBUG_print("\27[32mDefault metamanifest:\27[0m\n" .. tpretty(metamanifest_defaults))
    DEBUG_print("\27[32mProject metamanifest:\27[0m\n" .. tpretty(metamanifest_project))
    DEBUG_print("\27[32mFinal metamanifest:\27[0m\n" .. tpretty(metamanifest))

    metamanifest = process_ignored_paths(metamanifest)

    ----------------------------------------------------------------------------

    log("Copy template files")
    local new_files = { }
    copy_files_from_templates(
        root_template_name,
        root_template_paths,
        metamanifest,
        new_files
      )
    DEBUG_print("new_files :" .. tpretty(new_files))
    local file_dir_structure = create_directory_structure(new_files)
    DEBUG_print("file_dir_structure :" .. tpretty(file_dir_structure))

    local clean_up_data = tclone(file_dir_structure)

    ----------------------------------------------------------------------------

    log("Replicating data")
    local replicated_structure = do_replicate_data(
        metamanifest,
        file_dir_structure,
        CONFIG[TOOL_NAME].debug
      )
    DEBUG_print("file_dir_structure :" .. tpretty(file_dir_structure))
    DEBUG_print("replicated_structure :" .. tpretty(replicated_structure))

    ----------------------------------------------------------------------------

    log("Cleanup replication data")
    clean_up_replicate_data_recursively(
        metamanifest,
        metamanifest.project_path,
        clean_up_data
      )

    ----------------------------------------------------------------------------

    log("Filling placeholders")
    fill_placeholders(
        metamanifest,
        metamanifest.project_path,
        replicated_structure
      )

    ----------------------------------------------------------------------------

    log("Cleanup generated data")
    clean_up_generated_data_recursively(
        metamanifest,
        metamanifest.project_path,
        replicated_structure
      )

    log("Project " .. metamanifest.dictionary.PROJECT_NAME .. " created")
    return true
  end
end

--------------------------------------------------------------------------------

local EXTRA_HELP = [[

pk-project-create: fast project creation tool

Usage:

    pk-project-create <metamanifest_directory_path> <project_root_dir> [<template_dir>] [options]

Options:

    --debug                    Verbose output
]]

local CONFIG_SCHEMA = create_config_schema()

--------------------------------------------------------------------------------

local run = function(...)
  -- WARNING: Action-less tool. Take care when copy-pasting.

  CONFIG, ARGS = load_tools_cli_config(
      function(args) -- Parse actions
        local param = { }

        param.metamanifest_path = args[1] or args["--metamanifest_path"]
        param.root_project_path = args[2] or args["--root_project_path"]
        param.root_template_name = args[3] or args["--root_template_name"]
        param.root_template_paths = args["--root_template_paths"]
        param.debug = args["--debug"]
        return
        {
          PROJECT_PATH = args["--root"] or "";
          [TOOL_NAME] = param;
        }
      end,
      EXTRA_HELP,
      CONFIG_SCHEMA,
      luarocks_show_rock_dir("pk-project-tools.pk-project-create")
        .. "/src/lua/project-create/project-config/config.lua",
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

  ------------------------------------------------------------------------------

  create_project(
      CONFIG[TOOL_NAME].metamanifest_path,
      CONFIG[TOOL_NAME].root_project_path,
      CONFIG[TOOL_NAME].root_template_name,
      freeform_table_value(CONFIG[TOOL_NAME].root_template_paths)
    )
end

return
{
  run = run;
}
