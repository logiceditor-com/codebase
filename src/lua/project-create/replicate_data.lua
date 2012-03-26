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
  for k, v in ordered_pairs(dictionary) do
    if v == false then
      --find block
      local string_to_find = get_wrapped_string(k, block)
      local blocks = {}
      for w in string_to_process:gmatch(string_to_find) do
        blocks[#blocks + 1] = w
      end
      for j = 1, #blocks do
        --remove found block
        string_to_process = string_to_process:gsub(
            blocks[j]:gsub("[%p%%]", "%%%1"),
            "\n"
          )
      end
    end
  end
  return string_to_process
end

-- TODO: move to lua-nucleo #3736
local check_trailspaces_newlines = function(file_content)
  return file_content:gsub("[ \t]*\n", "\n"):gsub("\n\n[\n]+", "\n"):gsub("\n\n$", "\n")
end

local replace_pattern_in_string = function(
    string_to_process,
    key,
    value,
    data_wrapper
  )
  if is_string(value) then
    return string_to_process:gsub(
        data_wrapper.left:gsub("%p", "%%%1")
     .. key:gsub("%p", "%%%1")
     .. data_wrapper.right:gsub("%p", "%%%1"),
        (value:gsub("%%", "%%%1"))
      )
  elseif value == false then
    -- Remove all strings with pattern that == false
    return string_to_process:gsub(
        "\n[.]*"
     .. data_wrapper.left:gsub("%p", "%%%1")
     .. key:gsub("%p", "%%%1")
     .. data_wrapper.right:gsub("%p", "%%%1")
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
  for k, v in ordered_pairs(dictionary) do
    string_to_process =
      replace_pattern_in_string(string_to_process, k, v, data_wrapper)
  end
  return string_to_process
end

local replace_value_with_modificators_in_string = function(
    string_to_process,
    value,
    replacement,
    data_wrapper,
    modificator_wrapper,
    modificators
  )
  if is_table(modificators) then
    for mod, fn in ordered_pairs(modificators) do
      if is_string(replacement) and is_function(fn) then
        string_to_process = string_to_process:gsub(
            data_wrapper.left:gsub("%p", "%%%1")
         .. value:gsub("%p", "%%%1")
         .. data_wrapper.right:gsub("%p", "%%%1")
         .. modificator_wrapper.left:gsub("%p", "%%%1")
         .. mod:gsub("%p", "%%%1")
         .. modificator_wrapper.right:gsub("%p", "%%%1"),
            (fn(replacement):gsub("%%", "%%%1"))
          )
      end
    end
  end
  return replace_pattern_in_string(string_to_process, value, replacement, data_wrapper)
end

local replace_dictionary_with_modificators_in_string = function(
    string_to_process,
    dictionary,
    data_wrapper,
    modificator_wrapper,
    modificators
  )
  for k, v in ordered_pairs(dictionary) do
    string_to_process = replace_value_with_modificators_in_string(
        string_to_process,
        k,
        v,
        data_wrapper,
        modificator_wrapper,
        modificators
      )
  end
  return string_to_process
end

local check_string_has_patterns = function(string_to_process, data_wrapper)
  local pattern =
      data_wrapper.left:gsub("%p", "%%%1")
   .. '[^{}]-'
   .. data_wrapper.right:gsub("%p", "%%%1")
  if string_to_process:find(pattern) == nil then
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
      data_wrapper.left:gsub("%p", "%%%1")
   .. '[^{}]-'
   .. data_wrapper.right:gsub("%p", "%%%1")
   .. modificator_wrapper.left:gsub("%p", "%%%1")
   .. '[^{}]-'
   .. modificator_wrapper.right:gsub("%p", "%%%1")
  if string_to_process:find(pattern) == nil then
    return false
  end
  return true
end

local replace_value_in_string_using_parent = function(
    string_to_process,
    value,
    manifest,
    data_wrapper,
    modificator_wrapper,
    modificators
  )
  local manifest_current = manifest
  local dictionary_current = manifest_current.dictionary
  while is_table(dictionary_current) do
    -- DEBUG_print("\27[33mdictionary_current\27[0m ", tstr(dictionary_current))
    if dictionary_current[value] then
      return replace_value_with_modificators_in_string(
          string_to_process,
          value,
          dictionary_current[value],
          data_wrapper,
          modificator_wrapper,
          modificators
        )
    end
    if manifest_current.parent then
      manifest_current = manifest_current.parent
      dictionary_current = manifest_current.dictionary
    else
      dictionary_current = nil
    end
  end
  return string_to_process
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

local replace_dictionary_in_string_using_parent = function(
    string_to_process,
    dictionary,
    manifest,
    data_wrapper,
    modificator_wrapper,
    modificators
  )
  local manifest_current = manifest
  local dictionary_current = dictionary
  while is_table(dictionary_current) do
    string_to_process = replace_dictionary_in_string(
        string_to_process,
        dictionary_current,
        data_wrapper,
        modificator_wrapper,
        modificators
      )
    if manifest_current.parent then
      manifest_current = manifest_current.parent
      dictionary_current = manifest_current.dictionary
    else
      dictionary_current = nil
    end
  end
  return string_to_process
end

local function replicate_and_replace_in_file_recursively(
      manifest,
      file_content,
      replaces_used,
      wrapper,
      modificators,
      nested
    )

  local nested = nested or 0
  local replicate_data = tclone(manifest.replicate_data)
  local dictionary = tclone(manifest.dictionary)
  local subdictionary = manifest.subdictionary
  DEBUG_print("[" .. nested .. "] ","\27[33mRaRiFR\27[0m ")
  -- replace patterns already fixed for this part of text (or file)
  for k, v in ordered_pairs(replaces_used) do
    DEBUG_print("[" .. nested .. "] ","replaces_used k, v:",  k, v)
    if subdictionary[v] then

      file_content = replace_dictionary_in_string(
          file_content,
          subdictionary[v].dictionary,
          wrapper.data,
          wrapper.modificator,
          modificators
        )

      DEBUG_print(
          "[" .. nested .. "] ",
          "replace_dictionary_in_string file_content:\n",
          file_content, "\n"
        )
      -- append data of replacement subdictionaries
      for l, w in ordered_pairs(subdictionary[v].replicate_data) do
        replicate_data[l] = w
      end
      for l, w in ordered_pairs(subdictionary[v].dictionary) do
        dictionary[l] = w
        DEBUG_print(
            "[" .. nested .. "] ",
            tostring(w) .. " \27[33madded to dictionary as:\27[0m " .. tostring(l)
          )
      end
      for l, w in ordered_pairs(subdictionary[v].subdictionary) do
        subdictionary[l] = w
      end
    end
    file_content = file_content:gsub(
        wrapper.data.left .. k .. wrapper.data.right,
        wrapper.data.left .. v .. wrapper.data.right
      )
  end

  local top_level_blocks = find_top_level_blocks(file_content, wrapper.block, replaces_used)

  for i = 1, #top_level_blocks do
    local block = top_level_blocks[i]
    local value = block.value
    local text = block.text
    local value_replicates = find_replicate_data(manifest, value)
    block.replicas = { }

    -- "false" value processed here
    if tisempty(value_replicates) then
      block.replicas[#block.replicas + 1] = ""
    end

    -- replicated values processed here
    for j = 1, #value_replicates do
      local current_block_replica = text:gsub(
          wrapper.data.left:gsub("%p", "%%%1")
       .. value
       .. wrapper.data.right:gsub("%p", "%%%1"),
          wrapper.data.left
       .. value_replicates[j]
       .. wrapper.data.right
        )
      current_block_replica = replace_value_in_string_using_parent(
          current_block_replica,
          value_replicates[j],
          manifest,
          wrapper.data,
          wrapper.modificator,
          modificators
        )

      local submanifest = manifest
      if subdictionary[value_replicates[j]] then
        submanifest = subdictionary[value_replicates[j]]
      end
      local replaces_used_sub = tclone(replaces_used)
      replaces_used_sub[value] = value_replicates[j]

      current_block_replica = replicate_and_replace_in_file_recursively(
          submanifest,
          current_block_replica,
          replaces_used_sub,
          wrapper,
          modificators,
          nested + 1
        )

      current_block_replica = cut_wrappers(
          current_block_replica,
          wrapper.block,
          value
        )
      block.replicas[#block.replicas + 1] = current_block_replica
    end -- for j = 1, #value_replicates do

    file_content = file_content:gsub(
        block.text:gsub("[%p%%]", "%%%1"),
        table.concat(block.replicas, "")
      )
  end -- for i = 1, #top_level_blocks do

  -- removing blocks with "false" dictionary patterns
  file_content = remove_false_block(
      manifest,
      file_content,
      wrapper.block
    )

  file_content = remove_wrappers(file_content, wrapper.block)
  file_content = replace_dictionary_in_string_using_parent(
      file_content,
      dictionary,
      manifest,
      wrapper.data,
      wrapper.modificator,
      modificators
    )
  return file_content
end

--------------------------------------------------------------------------------

local replicate_and_replace_in_file = function(
    metamanifest,
    created_dir_structure,
    replaces_used,
    created_path
  )
  local file_content = read_file(created_path)
  file_content = replicate_and_replace_in_file_recursively(
      metamanifest,
      file_content,
      replaces_used,
      metamanifest.wrapper,
      metamanifest.modificators
    )
  file_content = check_trailspaces_newlines(file_content)
  write_file(created_path, file_content)
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
              filename = filenames[i].filename:gsub(pattern, replacements[j]);
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
           .. created_path:sub(#metamanifest.project_path + 2)
            )
          copy_file_force(filepath, created_path)
        end
        replicate_and_replace_in_file(
            metamanifest,
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
           .. filepath:sub(#metamanifest.project_path + 2)
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
