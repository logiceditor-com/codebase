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
  --common stuff----------------------------------------------------------------
  local DEBUG_print = function(...)
    if CONFIG[TOOL_NAME].debug then
      print(...)
    end
  end

  ------------------------------------------------------------------------------
  local copy_file_force  = function(path_from, path_to)
    create_path_to_file(path_to)
    copy_file_with_flag(path_from, path_to, "-f")
    return true
  end

  local check_path_ignored = function(short_path, ignore_paths)
    for k, v in pairs(ignore_paths) do
      -- if beginning of the path matches ignore path - it is ignored
      if ignore_paths[string.sub(short_path, 0, #k)] then
        return true
      end
    end
    return false
  end

  local get_dictionary_pattern = function(filename, metamanifest)
    local pattern = { }
    for k, _ in pairs(metamanifest.dictionary) do
      if filename:find(k) then
        pattern[#pattern + 1] = k
      end
    end
    return pattern
  end

  local break_path = function(path)
    local file_dir_list = { }
    -- TODO: Check if more symbols needed in regexp!!!
    for w in string.gmatch("/" .. path, "/[%w%._%-]+") do
      file_dir_list[#file_dir_list + 1] = string.sub(w, 2)
    end
    return file_dir_list
  end

  local add_to_directory_structure = function(new_file, dir_struct)
    local file_dir_list = { }
    file_dir_list = break_path(new_file)
    local dir_struct_curr = dir_struct or { }
    for j = 1, #file_dir_list do
      if not dir_struct_curr[file_dir_list[j]] then
        dir_struct_curr[file_dir_list[j]] = { ["FLAGS"] = { } }
      end
      dir_struct_curr.FLAGS = dir_struct_curr.FLAGS or { }
      dir_struct_curr.FLAGS["FILE"] = nil
      dir_struct_curr = dir_struct_curr[file_dir_list[j]]
    end
    dir_struct_curr.FLAGS["FILE"] = true
    return dir_struct
  end

  -- trying to make it somewhat generic
  local function process_dictionary_recursively(manifest, replaces, return_val, fn, ...)
    for k, v in pairs(replaces) do
      if manifest.subdictionary[v] then
        return_val = process_dictionary_recursively(
            manifest.subdictionary[v],
            replaces,
            return_val,
            fn,
            ...
          )
      end
    end
    return fn(manifest, return_val, ...)
  end

  -- get_replacement_pattern ---------------------------------------------------
  -- search dictionary and all used replaces subdictionaries for pattern match

  local get_replacement_pattern
  do
    local already_got = function(pattern, k)
      for i = 1, #pattern do
        if pattern[i] == k then
          return true
        end
      end
      return false
    end

    -- TODO: consider more clear subdictionary search,
    --       best of all try making single subdictionary searching function
    local function find_patterns_recursively(
        pattern,
        replaces_used,
        manifest,
        filename
      )
      for k, v in pairs(replaces_used) do
        if manifest.subdictionary[v] then
          for k, _ in pairs(manifest.subdictionary[v].replicate_data) do
            if filename:find(k) and not already_got(pattern, k) then
              pattern[#pattern + 1] = k
            end
          end
          pattern = find_patterns_recursively(
              pattern,
              replaces_used,
              manifest.subdictionary[v],
              filename
            )
        end
      end
      return pattern
    end

    get_replacement_pattern = function(filename, metamanifest, replaces_used)
      replaces_used = replaces_used or { }
      local pattern = { }
      for k, _ in pairs(metamanifest.replicate_data) do
        if filename:find(k) then
          pattern[#pattern + 1] = k
        end
      end
      return find_patterns_recursively(
          pattern,
          replaces_used,
          metamanifest,
          filename
        )
    end
  end

  -- TODO: generalize for all dictionary
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

  --copy_files------------------------------------------------------------------

  local copy_files = function(metamanifest, template_path, new_files)
    local all_template_files = find_all_files(template_path, ".*")

    -- string length of common part of all file paths
    local shift = 2 + string.len(template_path)

    if CONFIG[TOOL_NAME].debug then
      DEBUG_print("\27[33mDo not overwrite in\27[0m:")
      if metamanifest.ignore_paths then
        for k, v in pairs(metamanifest.ignore_paths) do
          DEBUG_print("  " .. k)
        end
      end
      DEBUG_print("\27[33mDo not copy in\27[0m:")
      if metamanifest.remove_paths then
        for k, v in pairs(metamanifest.remove_paths) do
          DEBUG_print("  " .. v)
        end
      end
    end

    for i = 1, #all_template_files do
      local short_path = string.sub(all_template_files[i], shift)
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

  --directory_structure---------------------------------------------------------

  local create_directory_structure
  do
    create_directory_structure = function(new_files)
      local dir_struct = { ["FLAGS"] = { } }
      local file_dir_list = { }
      for i = 1, #new_files do
        file_dir_list = break_path(new_files[i])
        local dir_struct_curr = dir_struct
        for j = 1, #file_dir_list do
          if not dir_struct_curr[file_dir_list[j]] then
            dir_struct_curr[file_dir_list[j]] = { ["FLAGS"] = { } }
          end
          dir_struct_curr = dir_struct_curr[file_dir_list[j]]
        end
        dir_struct_curr.FLAGS["FILE"] = true
      end
      return dir_struct
    end
  end

  --do_replicate_data-----------------------------------------------------------

  local do_replicate_data
  do
    local function make_plain_dictionary(dictionary)
      local replicate_data = { }
      local processed = { }
      local subdictionary = { }

      for k, v in pairs(dictionary) do
        if is_table(v) then
          replicate_data[#replicate_data + 1] = k
        elseif v == true then -- TODO: subject to revise
          dictionary[k] = nil
          DEBUG_print(k .. "\27[32mremoved as it was\27[0m:\n" .. tostring(v))
        end
      end

      for i = 1, #replicate_data do
        local data = replicate_data[i]
        local replicate = dictionary[data]
        replicate_data[data] = { }
        for j = 1, #replicate do
          local name = string.sub(data, 1, -2) .. "_" .. string.format("%03d", j)
          dictionary[name] = replicate[j]
          replicate_data[data][j] = name
          subdictionary[name] = replicate[replicate[j]]
          if is_table(subdictionary[name]) then
            subdictionary[name] = make_plain_dictionary(subdictionary[name])
          end
        end
        processed[data] = tclone(dictionary[data])
        dictionary[data] = nil
        replicate_data[i] = nil
      end

      return {
        dictionary = dictionary;
        replicate_data = replicate_data;
        processed = processed;
        subdictionary = subdictionary;
      }
    end

    local process_pattern_combination
    do
    -- TODO: consider more clear subdictionary search,
    --       best of all try making single subdictionary searching function
      local function find_replacements_recursively(
          pattern,
          replacements,
          replaces_used,
          manifest
        )
        for k, v in ordered_pairs(replaces_used) do
          if manifest.subdictionary[v] then
            if
              manifest.subdictionary[v].replicate_data
              and manifest.subdictionary[v].replicate_data[pattern]
            then
              replacements = manifest.subdictionary[v].replicate_data[pattern]
            -- TODO: this is spagetti code, consider reworking it
            elseif manifest.subdictionary[v].dictionary[pattern] == false then
              replacements = false
            end
            replacements = find_replacements_recursively(
                pattern,
                replacements,
                replaces_used,
                manifest.subdictionary[v]
              )
          end
        end
        return replacements
      end

      process_pattern_combination = function(pattern, filenames, metamanifest)
        local new_filenames = { }
        for i = 1, #filenames do
          local replacements = { }
          if filenames[i].replaces_used[pattern] ~= nil then
            replacements[1] = filenames[i].replaces_used[pattern]
          else
            replacements = find_replacements_recursively(
                pattern,
                replacements,
                filenames[i].replaces_used,
                metamanifest
              )
            if replacements and #replacements == 0 then
              replacements = metamanifest.replicate_data[pattern]
            elseif replacements == false then
              replacements = { }
            end
          end

          for j = 1, #replacements do
            local replaces_used = tclone(filenames[i].replaces_used)
            replaces_used[pattern] = replacements[j]
            new_filenames[#new_filenames + 1] =
              {
                filename = string.gsub(filenames[i].filename, pattern, replacements[j]);
                replaces_used = replaces_used;
              }
          end
        end
        return new_filenames
      end
    end

    local process_pattern_combinations = function(patterns, filenames, metamanifest)
      local new_filenames = filenames
      while #patterns > 0 do
        local pattern = table.remove(patterns)
        new_filenames = process_pattern_combination(
            pattern,
            new_filenames,
            metamanifest
          )
      end
      return new_filenames
    end

    local get_wrapped_string = function(string_to_process, wrapper)
      local block_top_wrapper =
        string.gsub(wrapper.top.left, "%p", "%%%1") .. string_to_process ..
        string.gsub(wrapper.top.right, "%p", "%%%1")
      local block_bottom_wrapper =
        string.gsub(wrapper.bottom.left, "%p", "%%%1") .. string_to_process ..
        string.gsub(wrapper.bottom.right, "%p", "%%%1")
      return
        block_top_wrapper .. ".-" .. block_bottom_wrapper,
        block_top_wrapper,
        block_bottom_wrapper
    end

    local remove_false_block = function(manifest, string_to_process, block)
      local dictionary = manifest.dictionary
      for k, v in pairs(dictionary) do
        if v == false then
          --find block
          local string_to_find = get_wrapped_string(k, block)
          local blocks = {}
          for w in string.gmatch(string_to_process, string_to_find) do
            blocks[#blocks + 1] = w
          end
          for j = 1, #blocks do
          --remove found block
            string_to_process = string.gsub(
                string_to_process,
                string.gsub(blocks[j], "[%p%%]", "%%%1"),
                "\n"
              )
          end
        end
      end
      return string_to_process
    end

    local process_replication_recursively
    do
      local check_trailspaces_newlines = function(file_content)
        file_content = string.gsub(file_content, "[ \t]*\n", "\n")
        file_content = string.gsub(file_content, "\n\n[\n]+", "\n")
        file_content = string.gsub(file_content, "\n\n$", "\n")
        return file_content
      end

      local replace_pattern_in_string = function(
          string_to_process,
          key,
          value,
          data_wrapper
        )
        if is_string(value) then
          DEBUG_print("Dictionary ",  tostring(key), tostring(value))
          local to_insert = string.gsub(value, "%%", "%%%1")
          return string.gsub(
              string_to_process,
              string.gsub(data_wrapper.left, "%p", "%%%1")
           .. string.gsub(key, "%p", "%%%1")
           .. string.gsub(data_wrapper.right, "%p", "%%%1"),
              to_insert
            )
        elseif value == false then
          -- Remove all strings with pattern that == false
          return string.gsub(
              string_to_process,
              "\n[.]*"
           .. string.gsub(data_wrapper.left, "%p", "%%%1")
           .. string.gsub(key, "%p", "%%%1")
           .. string.gsub(data_wrapper.right, "%p", "%%%1")
           .. "[.]*\n",
              "\n"
            )
        else
          log_error(
              value,
              " is not string or false in manifest dictionary for",
              key
            )
          error("manifest dictionary has not string or false value")
        end
      end

      local replace_simple_dictionary_in_string = function(
          string_to_process,
          dictionary,
          data_wrapper
        )
        for k, v in pairs(dictionary) do
          string_to_process =
            replace_pattern_in_string(string_to_process, k, v, data_wrapper)
        end
        return string_to_process
      end

      local replace_dictionary_with_modificators_in_string = function(
          string_to_process,
          dictionary,
          data_wrapper,
          modificator_wrapper,
          modificators
        )
        for k, v in pairs(dictionary) do
          for mod, fn in pairs(modificators) do
            if is_string(v) and is_function(fn) then
              local to_insert = string.gsub(fn(v), "%%", "%%%1")
              string_to_process = string.gsub(
                  string_to_process,
                  string.gsub(data_wrapper.left, "%p", "%%%1")
               .. string.gsub(k, "%p", "%%%1")
               .. string.gsub(data_wrapper.right, "%p", "%%%1")
               .. string.gsub(modificator_wrapper.left, "%p", "%%%1")
               .. string.gsub(mod, "%p", "%%%1")
               .. string.gsub(modificator_wrapper.right, "%p", "%%%1"),
                  to_insert
                )
            end
          end
          string_to_process =
            replace_pattern_in_string(string_to_process, k, v, data_wrapper)
        end
        return string_to_process
      end

      local check_string_has_patterns = function(string_to_process, data_wrapper)
        local pattern =
            string.gsub(data_wrapper.left, "%p", "%%%1")
         .. '[^{}]-'
         .. string.gsub(data_wrapper.right, "%p", "%%%1")
        if string.find(string_to_process, pattern) == nil then
          return false
        end
        return true
      end

      local check_string_has_modificators = function(
          string_to_process,
          data_wrapper,
          modificator_wrapper
        )
        local pattern =
            string.gsub(data_wrapper.left, "%p", "%%%1")
         .. '[^{}]-'
         .. string.gsub(data_wrapper.right, "%p", "%%%1")
         .. string.gsub(modificator_wrapper.left, "%p", "%%%1")
         .. '[^{}]-'
         .. string.gsub(modificator_wrapper.right, "%p", "%%%1")
        if string.find(string_to_process, pattern) == nil then
          return false
        end
        return true
      end

      local replace_dictionary_in_string = function(
          string_to_process,
          dictionary,
          data_wrapper,
          modificator_wrapper,
          modificators
        )
        if not check_string_has_patterns(string_to_process, data_wrapper) then
          return string_to_process
        end
        if
          not check_string_has_modificators(
              string_to_process,
              data_wrapper,
              modificator_wrapper
            )
        then
          return replace_simple_dictionary_in_string(
              string_to_process,
              dictionary,
              data_wrapper
            )
        end

        return replace_dictionary_with_modificators_in_string(
            string_to_process,
            dictionary,
            data_wrapper,
            modificator_wrapper,
            modificators
          )
      end

      local function replicate_and_replace_in_file_recursively(
            manifest,
            file_content,
            replaces_used,
            wrapper,
            modificators
          )
        -- TODO: check if pattern exists in file(string)
        local current_block_replica = ""
        local blocks = { }
        local replicate_data = manifest.replicate_data
        local dictionary = manifest.dictionary
        local subdictionary = manifest.subdictionary

        -- replace patterns already fixed for this file
        for k, v in pairs(replaces_used) do
          DEBUG_print(" k, v:",  k, v)
          if manifest.subdictionary[v] then
            DEBUG_print("file_content:",  file_content)
            file_content = replace_dictionary_in_string(
                file_content,
                manifest.subdictionary[v].dictionary,
                wrapper.data,
                wrapper.modificator,
                modificators
              )
            DEBUG_print("replace_dictionary_in_string file_content:",  file_content)
            -- append data of replacement subdictionaries
            for l, w in pairs(manifest.subdictionary[v].replicate_data) do
              replicate_data[l] = w
            end
            for l, w in pairs(manifest.subdictionary[v].dictionary) do
              dictionary[l] = w
              DEBUG_print(tostring(w) .. " \27[33madded to dictionary as:\27[0m " .. tostring(l))
            end
            for l, w in pairs(manifest.subdictionary[v].subdictionary) do
              subdictionary[l] = w
            end
          end
          file_content = string.gsub(
              file_content,
              wrapper.data.left .. k .. wrapper.data.right,
              wrapper.data.left .. v .. wrapper.data.right
            )
        end

        -- replicate blocks
        for k, v in pairs(replicate_data) do
          --find block
          local string_to_find, block_top_wrapper, block_bottom_wrapper =
            get_wrapped_string(k, wrapper.block)
          blocks = { }
          for w in string.gmatch(file_content, string_to_find) do
            blocks[#blocks + 1] = w
          end
          --form new block
          local blocks_set_to_write = { }
          for j = 1, #blocks do
            blocks_set_to_write[j] = { }
            for i = 1, #v do
              current_block_replica = blocks[j]
              -- insert replica instead of general marker
              current_block_replica = string.gsub(
                  current_block_replica,
                  string.gsub(wrapper.data.left, "%p", "%%%1")
               .. k
               .. string.gsub(wrapper.data.right, "%p", "%%%1"),
                  wrapper.data.left .. v[i] .. wrapper.data.right
                )
              -- sub dictionary replaces
              if subdictionary[v[i]] then
                -- recursion here
                local replaces_used_sub = replaces_used
                replaces_used_sub[k] = v[i]
                current_block_replica = replicate_and_replace_in_file_recursively(
                    subdictionary[v[i]],
                    current_block_replica,
                    replaces_used_sub,
                    wrapper,
                    modificators
                  )
              end

              -- cut block wrappers
              current_block_replica =
                string.gsub(current_block_replica, block_top_wrapper .. "\n", "")
              current_block_replica =
                string.gsub(current_block_replica, "\n" .. block_bottom_wrapper, "")

              blocks_set_to_write[j][i] = current_block_replica
            end

            --replace found block
            file_content = string.gsub(
                file_content,
                string.gsub(blocks[j], "[%p%%]", "%%%1"),
                table.concat(blocks_set_to_write[j], "\n")
              )
          end -- for j = 1, #blocks do
        end -- for k, v in pairs(replicate_data) do

        -- removing blocks with "false" dictionary patterns
        file_content = remove_false_block(
            manifest,
            file_content,
            wrapper.block
          )
        file_content = replace_dictionary_in_string(
            file_content,
            dictionary,
            wrapper.data,
            wrapper.modificator,
            modificators
          )
        file_content = check_trailspaces_newlines(file_content)
        return file_content
      end

      local replicate_and_replace_in_file = function(
          metamanifest,
          created_dir_structure,
          replaces_used,
          created_path
        )
        local file = assert(io.open(created_path, "r"))
        local file_content = file:read("*all")
        file:close()

        file_content = replicate_and_replace_in_file_recursively(
            metamanifest,
            file_content,
            replaces_used,
            metamanifest.wrapper,
            metamanifest.modificators
          )
        file = io.open(created_path, "w")
        file:write(file_content)
        file:close()
      end

      local process_curr_path = function(
          attr,
          created_path,
          filepath,
          replaces_used,
          metamanifest,
          file_dir_structure,
          created_dir_structure
        )
        if attr.mode == "directory" then
          create_path_to_file(created_path .. "/.")
          -- TODO: sanity check must work
          -- assert(file_dir_structure.FLAGS.FILE == nil, "dir structure sanity check")
          process_replication_recursively(
             {
               existed_path = filepath,
               created_path = created_path,
               existed_structure = file_dir_structure,
               created_structure = created_dir_structure,
               replaces_used = replaces_used
             },
             metamanifest
           )
        else
          if filepath ~= created_path then
            DEBUG_print(
                "\27[32mCopy to:\27[0m "
             .. string.sub(created_path, #metamanifest.project_path + 2)
              )
            copy_file_force(filepath, created_path)
          end
          local manifest_copy = tclone(metamanifest)
          replicate_and_replace_in_file(
              manifest_copy,
              created_dir_structure,
              replaces_used,
              created_path
            )
        end
      end

      process_replication_recursively = function(
          path_data,
          metamanifest
        )
        for filename, structure in pairs(path_data.existed_structure) do
          if filename ~= "FLAGS" then
            local filepath = path_data.existed_path .. "/" .. filename
            local attr = lfs.attributes(filepath)
            DEBUG_print(
                "\27[37mProcess: "
             .. string.sub(filepath, #metamanifest.project_path + 2)
             .. " (" .. attr.mode .. ")\27[0m")
            local pattern_used = get_replacement_pattern(
                filename,
                metamanifest,
                path_data.replaces_used
              )

            -- filename have patterns to replicate
            if #pattern_used > 0 then
              local pattern_combinations = process_pattern_combinations(
                  pattern_used,
                  {
                    {
                      filename = filename;
                      replaces_used = path_data.replaces_used;
                    };
                  },
                  metamanifest
                )
              for i = 1, #pattern_combinations do
                -- create paths
                local created_path =
                  path_data.created_path .. "/" .. pattern_combinations[i].filename
                local replaces_used = tclone(pattern_combinations[i].replaces_used)
                path_data.created_structure = add_to_directory_structure(
                    pattern_combinations[i].filename,
                    path_data.created_structure
                  )
                local structure_new = path_data.created_structure[pattern_combinations[i].filename]
                structure_new.FLAGS["replaces_used"] = replaces_used
                -- recursion hided here
                process_curr_path(
                    attr,
                    created_path,
                    filepath,
                    replaces_used,
                    metamanifest,
                    structure,
                    structure_new
                  )
              end

            -- filename has no patterns to replicate
            else
              local created_path = path_data.created_path .. "/" .. filename
              local replaces_used = tclone(path_data.replaces_used)

              path_data.created_structure = add_to_directory_structure(
                  filename,
                  path_data.created_structure
                )
              local structure_new = path_data.created_structure[filename]
              structure_new.FLAGS["replaces_used"] = replaces_used
              -- recursion hided here
              process_curr_path(
                    attr,
                    created_path,
                    filepath,
                    replaces_used,
                    metamanifest,
                    structure,
                    structure_new
                )
            end
          end -- if filename ~= "FLAGS"
        end -- filename, structure in pairs(file_dir_structure) do
        return path_data.created_structure
      end -- process_replication_recursively

    end -- do

    do_replicate_data = function(
        metamanifest,
        file_dir_structure
      )
      -- TODO: this is bad, make it smarter
      local metamanifest_plain = make_plain_dictionary(metamanifest.dictionary)
      metamanifest.dictionary = metamanifest_plain.dictionary
      metamanifest.replicate_data = metamanifest_plain.replicate_data
      metamanifest.processed = metamanifest_plain.processed
      metamanifest.subdictionary = metamanifest_plain.subdictionary

      -- no dictionary replacements
      return process_replication_recursively(
          {
            existed_path = metamanifest.project_path,
            created_path = metamanifest.project_path,
            existed_structure = file_dir_structure,
            created_structure = { ["FLAGS"] = { } },
            replaces_used = { }
          },
          metamanifest
        )
    end
  end

  --clean_up_replicate_data-----------------------------------------------------

  local function clean_up_replicate_data_recursively(metamanifest, path, file_dir_structure)
    for filename, structure in pairs(file_dir_structure) do
      if filename ~= "FLAGS" then
        local filepath = path .. "/" .. filename

        -- TODO: BAD handle through dir structure
        if does_file_exist(filepath) then
          local attr = assert(lfs.attributes(filepath))

          -- TODO: replace on reading file_dir_structure FLAGS?
          local pattern_used = get_replacement_pattern(filename, metamanifest)

          if #pattern_used > 0 then
            DEBUG_print("\27[33mRemoved:\27[0m " .. string.sub(filepath, #metamanifest.project_path + 2))
            remove_recursively(filepath)
          else
            local attr = assert(lfs.attributes(filepath))
            if attr.mode == "directory" then
              clean_up_replicate_data_recursively(metamanifest, filepath, structure)
            end
          end
        end
      end

    end
  end

  --fill_placeholders-----------------------------------------------------------

  local fill_placeholders
  do
    local replace_pattern = function(manifest, new_filepath)
      for k, v in pairs(manifest.dictionary) do
        if new_filepath:find(k) then
          if v ~= false then
            return string.gsub(new_filepath, k, v)
          else
            return ""
          end
        end
      end
      return new_filepath
    end

    local replace_dictionary_patterns_in_path = function(filepath, metamanifest, replaces)
      local new_filepath = filepath
      new_filepath = process_dictionary_recursively(
          metamanifest,
          replaces,
          new_filepath,
          replace_pattern
        )

      for k, v in pairs(metamanifest.dictionary) do
        if new_filepath:find(k) then
          if v ~= false then
            new_filepath = string.gsub(new_filepath, k, v);
          else
            DEBUG_print("\27[33mFalse  : " .. filepath .. "\27[0m")
            return
          end
        end
      end

      local short_path = string.sub(filepath, #metamanifest.project_path + 2)
      local short_path_new = string.sub(new_filepath, #metamanifest.project_path + 2)
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

    fill_placeholders = function(
        metamanifest, path, file_dir_structure
      )
      metamanifest.cleanup = { }
      for filename, structure in pairs(file_dir_structure) do
        if filename ~= "FLAGS" then
          local filepath = path .. "/" .. filename
          DEBUG_print("\27[32mProcess:\27[0m " .. string.sub(filepath, #metamanifest.project_path + 2))
          local attr = lfs.attributes(filepath)
          if attr.mode == "directory" then
            fill_placeholders(metamanifest, filepath, structure)
          else
            DEBUG_print("structure: ", tpretty(structure))
            replace_dictionary_patterns_in_path(filepath, metamanifest, structure.FLAGS.replaces_used)
          end
        end
      end
    end
  end

  --clean_up_replicate_data-----------------------------------------------------

  local function clean_up_generated_data_recursively(
      metamanifest,
      path,
      file_dir_structure
    )
    for filename, structure in pairs(file_dir_structure) do
      if filename ~= "FLAGS" then
        local filepath = path .. "/" .. filename

        -- TODO: BAD handle through dir structure
        if does_file_exist(filepath) then
          local attr = assert(lfs.attributes(filepath))

          -- TODO: replace on reading file_dir_structure FLAGS?
          local pattern_used = get_dictionary_pattern(filename, metamanifest)

          if #pattern_used > 0 then
            DEBUG_print(
                "\27[33mRemoved: "
             .. string.sub(filepath, #metamanifest.project_path + 2)
             .. "\27[0m"
              )
            remove_recursively(filepath)
          else
            local attr = assert(lfs.attributes(filepath))
            if attr.mode == "directory" then
              DEBUG_print(
                  "\27[32mChecked:\27[0m "
               .. string.sub(filepath, #metamanifest.project_path + 2)
                )
              clean_up_generated_data_recursively(metamanifest, filepath, structure)
            end
          end
        end
      end

    end
  end

  ------------------------------------------------------------------------------

  local unify_manifest_dictionary
  do
    unify_manifest_dictionary = function(dictionary)
      for k, v in pairs(dictionary) do
        if is_table(v) then
          --check all values where key is number
          local i = 1
          while v[i] ~= nil do
            if is_table(v[i]) then
              if v[i].name ~= nil then
                local name = v[i].name
                v[name] = { }
                for k_local, v_local in pairs(v[i]) do
                  if k_local ~= "name" then
                    v[name][k_local] = v[i][k_local]
                    v[i][k_local] = nil
                  end
                end
                v[i] = name
              end
            end
            i = i + 1
          end
          v = unify_manifest_dictionary(v)
        end
      end --for
      return dictionary
    end
  end -- do

  ------------------------------------------------------------------------------

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
    local replicated_structure = do_replicate_data(metamanifest, file_dir_structure)
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
