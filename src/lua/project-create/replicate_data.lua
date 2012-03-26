--------------------------------------------------------------------------------
-- replicate_data.lua: project-create replicate functions
-- This file is a part of pk-project-tools library
-- Copyright (c) Alexander Gladysh <ag@logiceditor.com>
-- Copyright (c) Dmitry Potapov <dp@logiceditor.com>
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

local loadfile, loadstring = loadfile, loadstring

--------------------------------------------------------------------------------

local log, dbg, spam, log_error
      = import 'pk-core/log.lua' { 'make_loggers' } (
          "project-create/replicate-data", "RPD"
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
      tiflip,
      tisempty
      = import 'lua-nucleo/table-utils.lua'
      {
        'tgetpath',
        'tclone',
        'twithdefaults',
        'tset',
        'tiflip',
        'tisempty'
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

local split_by_char
      = import 'lua-nucleo/string.lua'
      {
        'split_by_char'
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
      find_top_level_blocks,
      find_replicate_data,
      get_wrapped_string,
      cut_wrappers,
      remove_wrappers
      = import 'pk-project-create/common_functions.lua'
      {
        'copy_file_force',
        'check_path_ignored',
        'get_dictionary_pattern',
        'break_path',
        'add_to_directory_structure',
        'process_dictionary_recursively',
        'get_replacement_pattern',
        'find_top_level_blocks',
        'find_replicate_data',
        'get_wrapped_string',
        'cut_wrappers',
        'remove_wrappers'
      }

--------------------------------------------------------------------------------

local debug_value

local DEBUG_print = function(...)
  if debug_value ~= false then -- ~= false then
    print(...)
  end
end

--------------------------------------------------------------------------------

local function make_plain_dictionary(dictionary, parent)
  local parent = parent or nil
  local replicate_data = { }
  local processed = { }
  local subdictionary = { }

  for k, v in ordered_pairs(dictionary) do
    if is_table(v) then
      replicate_data[#replicate_data + 1] = k
    elseif v == false then
      DEBUG_print(k .. " - \27[32mfalse\27[0m : going to make empty")
      replicate_data[#replicate_data + 1] = k
    end
  end

  for i = 1, #replicate_data do
    DEBUG_print("Going through replicate data:", replicate_data[i])
    local data = replicate_data[i]
    local replicate = dictionary[data]
    DEBUG_print("replicate", replicate_data[i])
    replicate_data[data] = { }
    if is_table(replicate) then
      for j = 1, #replicate do
        local name = data:sub(1, -2) .. "_" .. string.format("%03d", j)
        dictionary[name] = replicate[j]
        replicate_data[data][j] = name
        subdictionary[name] = replicate[replicate[j]]
        if is_table(subdictionary[name]) then
          subdictionary[name] = make_plain_dictionary(subdictionary[name], dictionary)
        end
      end
      processed[data] = tclone(dictionary[data])
    end
    dictionary[data] = nil
    replicate_data[i] = nil
  end
  local result =
  {
    dictionary = dictionary;
    replicate_data = replicate_data;
    processed = processed;
    subdictionary = subdictionary;
  }
  -- so we can always reach parent table from subtable,
  -- though this makes our dictionary data structure heavily recursive
  for k, v in ordered_pairs(subdictionary) do
    subdictionary[k].parent = result
  end
  return result
end

--------------------------------------------------------------------------------

local prepare_manifest = function(metamanifest)
  local metamanifest_plain = make_plain_dictionary(metamanifest.dictionary)
  metamanifest.dictionary = metamanifest_plain.dictionary
  metamanifest.replicate_data = metamanifest_plain.replicate_data
  metamanifest.processed = metamanifest_plain.processed
  metamanifest.subdictionary = metamanifest_plain.subdictionary
  return metamanifest
end

--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------

local do_replicate_data
do
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

  local process_replication_recursively
  do
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
      file_dir_structure,
      debug
    )
    debug_value = debug or false

    -- no dictionary replacements
    return process_replication_recursively(
        {
          existed_path = metamanifest.project_path,
          created_path = metamanifest.project_path,
          existed_structure = file_dir_structure,
          created_structure = { ["FLAGS"] = { } },
          replaces_used = { }
        },
        prepare_manifest(metamanifest)
      )
  end
end

return
{
  do_replicate_data = do_replicate_data;
  make_plain_dictionary = make_plain_dictionary;
  prepare_manifest = prepare_manifest;
  replicate_and_replace_in_file_recursively = replicate_and_replace_in_file_recursively;
}
