--------------------------------------------------------------------------------
-- copy_files.lua: methods of project-create
-- This file is a part of pk-project-tools library
-- Copyright (c) Alexander Gladysh <ag@logiceditor.com>
-- Copyright (c) Dmitry Potapov <dp@logiceditor.com>
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

local loadfile, loadstring = loadfile, loadstring

--------------------------------------------------------------------------------

local log, dbg, spam, log_error
      = import 'pk-core/log.lua' { 'make_loggers' } (
          "project-create/copy-files", "CPF"
        )

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
      create_directory_structure
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
        'create_directory_structure'
      }

local do_replicate_data
      = import 'pk-project-create/replicate_data.lua'
      {
        'do_replicate_data'
      }

--------------------------------------------------------------------------------

local debug_value

local DEBUG_print = function(...)
  if debug_value then -- ~= false then
    print(...)
  end
end

local copy_files = function(metamanifest, template_path, new_files)
  local all_template_files = find_all_files(template_path, ".*")

  -- string length of common part of all file paths
  local shift = 2 + #template_path

  if CONFIG[TOOL_NAME].debug then
    DEBUG_print("\27[33mDo not overwrite in\27[0m:")
    if metamanifest.ignore_paths then
      for k, v in ordered_pairs(metamanifest.ignore_paths) do
        DEBUG_print("  " .. k)
      end
    end
    DEBUG_print("\27[33mDo not copy in\27[0m:")
    if metamanifest.remove_paths then
      for k, v in ordered_pairs(metamanifest.remove_paths) do
        DEBUG_print("  " .. v)
      end
    end
  end

  for i = 1, #all_template_files do
    local short_path = all_template_files[i]:sub(shift)
    local project_filepath = metamanifest.project_path .. "/" .. short_path
    if
      metamanifest.remove_paths
      and check_path_ignored(short_path, tset(metamanifest.remove_paths))
    then
      DEBUG_print("\27[33mRemoved:\27[0m " .. short_path)
    elseif
      metamanifest.ignore_paths
      and check_path_ignored(short_path, metamanifest.ignore_paths)
      and does_file_exist(project_filepath)
    then
      DEBUG_print("\27[33mIgnored:\27[0m " .. short_path)
    else
      -- do not overwrite if not flag --force used
      DEBUG_print("\27[32mCopy to:\27[0m " .. short_path)
      if copy_file_force(all_template_files[i], project_filepath) then
        new_files[#new_files + 1] = short_path
      end
    end
  end

  return new_files
end

local get_template_path = function(name, paths)
  for i = 1, #paths do
    local path = paths[i].path .. "/" .. name .. ".template"
    DEBUG_print("Checking path " .. path)
    if does_file_exist(path) then
      DEBUG_print("Exists!")
      return path
    end
  end
  error("Template " .. name .. " not found in paths: " .. tstr(paths))
end

local function copy_files_from_templates(name, paths, metamanifest, new_files)
  local path = get_template_path(name, paths)
  log("Template path:", path)
  local config_path = path .. "/template_config"
  if does_file_exist(config_path) then
    log("Template config:", config_path)
    local template_metamanifest = load_project_manifest(
        config_path, "", ""
      )
    for i = 1, #template_metamanifest.parent_templates do
      copy_files_from_templates(
          template_metamanifest.parent_templates[i].name,
          paths,
          metamanifest,
          new_files
        )
    end
  else
    DEBUG_print("No template config found for " .. name)
  end
  DEBUG_print("\27[37mTemplates_path:\27[0m " .. path)
  copy_files(metamanifest, path, new_files)
  DEBUG_print("new files :" .. tpretty(new_files))
end

--------------------------------------------------------------------------------

local function clean_up_fs_recursively(
    metamanifest,
    path,
    file_dir_structure,
    get_pattern
  )
  for filename, structure in ordered_pairs(file_dir_structure) do
    if filename ~= "FLAGS" then
      local filepath = path .. "/" .. filename

      -- TODO: BAD handle through dir structure
      if does_file_exist(filepath) then
        local attr = assert(lfs.attributes(filepath))

        -- TODO: replace on reading file_dir_structure FLAGS?
        local pattern_used = get_pattern(filename, metamanifest)

        if #pattern_used > 0 then
          DEBUG_print(
              "\27[33mRemoved:\27[0m "
           .. filepath:sub(#metamanifest.project_path + 2)
            )
          remove_recursively(filepath)
        else
          local attr = assert(lfs.attributes(filepath))
          if attr.mode == "directory" then
            DEBUG_print(
                "\27[32mChecked:\27[0m "
             .. filepath:sub(#metamanifest.project_path + 2)
              )
            clean_up_fs_recursively(metamanifest, filepath, structure, get_pattern)
          end
        end
      end
    end
  end
end

local clean_up_replicate_data_recursively = function(
    metamanifest,
    path,
    file_dir_structure
  )
  return clean_up_fs_recursively(
      metamanifest,
      path,
      file_dir_structure,
      get_replacement_pattern
    )
end

local clean_up_generated_data_recursively = function(
    metamanifest,
    path,
    file_dir_structure
  )
  return clean_up_fs_recursively(
      metamanifest,
      path,
      file_dir_structure,
      get_dictionary_pattern
    )
end

--------------------------------------------------------------------------------

local fill_placeholders_in_template
do
  local replace_pattern = function(manifest, new_filepath)
    for k, v in ordered_pairs(manifest.dictionary) do
      if new_filepath:find(k, nil, true) then
        if v ~= false then
          return new_filepath:gsub(k, v)
        else
          return ""
        end
      end
    end
    return new_filepath
  end

  local replace_dictionary_patterns_in_path = function(
      filepath,
      metamanifest,
      replaces
    )
    local new_filepath = filepath
    new_filepath = process_dictionary_recursively(
        metamanifest,
        replaces,
        new_filepath,
        replace_pattern
      )

    for k, v in ordered_pairs(metamanifest.dictionary) do
      if new_filepath:find(k, nil, true) then
        if v ~= false then
          new_filepath = new_filepath:gsub(k, v)
        else
          DEBUG_print("\27[33mFalse  : " .. filepath .. "\27[0m")
          return
        end
      end
    end

    local short_path = filepath:sub(#metamanifest.project_path + 2)
    local short_path_new = new_filepath:sub(#metamanifest.project_path + 2)

    -- TODO: vaible way?
    if filepath ~= new_filepath then
      if
        check_path_ignored(short_path_new, metamanifest.ignore_paths)
        and does_file_exist(new_filepath)
      then
        DEBUG_print("\27[33mIgnored: " .. short_path_new .. "\27[0m")
        remove_recursively(filepath)
        DEBUG_print("\27[31mRemoved: " .. short_path .. "\27[0m")
      elseif new_filepath ~= "" then
        create_path_to_file(new_filepath)
        assert(os.rename(filepath, new_filepath), filepath .. " -> " .. new_filepath)
        DEBUG_print("\27[33mRenamed:\27[0m " .. short_path_new)
      else
        remove_recursively(filepath)
        DEBUG_print("\27[31mCleaned: " .. short_path .. "\27[0m")
      end
    end
  end

  fill_placeholders_in_template = function(
      metamanifest, path, file_dir_structure
    )
    metamanifest.cleanup = { }
    for filename, structure in ordered_pairs(file_dir_structure) do
      if filename ~= "FLAGS" then
        local filepath = path .. "/" .. filename
        DEBUG_print("\27[32mProcess:\27[0m " .. filepath:sub(#metamanifest.project_path + 2))
        local attr = lfs.attributes(filepath)
        if attr.mode == "directory" then
          fill_placeholders_in_template(metamanifest, filepath, structure)
        else
          DEBUG_print("structure: ", tpretty(structure))
          replace_dictionary_patterns_in_path(
              filepath,
              metamanifest,
              structure.FLAGS.replaces_used
            )
        end
      end
    end
  end
end

--------------------------------------------------------------------------------

return
{
  copy_files_from_templates = copy_files_from_templates;
  clean_up_replicate_data_recursively = clean_up_replicate_data_recursively;
  clean_up_generated_data_recursively = clean_up_generated_data_recursively;
  fill_placeholders_in_template = fill_placeholders_in_template;
}
