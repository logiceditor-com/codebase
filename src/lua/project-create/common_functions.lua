--------------------------------------------------------------------------------
-- common_functions.lua: project-create common functions
-- This file is a part of pk-project-tools library
-- Copyright (c) Alexander Gladysh <ag@logiceditor.com>
-- Copyright (c) Dmitry Potapov <dp@logiceditor.com>
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

local loadfile, loadstring = loadfile, loadstring

--------------------------------------------------------------------------------

local log, dbg, spam, log_error
      = import 'pk-core/log.lua' { 'make_loggers' } (
          "project-create/common_functions", "PCC"
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
      empty_table
      = import 'lua-nucleo/table-utils.lua'
      {
        'tgetpath',
        'tclone',
        'twithdefaults',
        'tset',
        'tiflip',
        'empty_table'
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

--------------------------------------------------------------------------------

local copy_file_force  = function(path_from, path_to)
  arguments(
      "string", path_from,
      "string", path_to
    )
  create_path_to_file(path_to)
  copy_file_with_flag(path_from, path_to, "-f")
  return true
end

--------------------------------------------------------------------------------

local check_path_ignored = function(short_path, ignore_paths)
  ignore_paths = ignore_paths or empty_table
  arguments(
      "string", short_path,
      "table", ignore_paths
    )
  for k, v in ordered_pairs(ignore_paths) do
    -- if beginning of the path matches ignore path - it is ignored
    if ignore_paths[short_path:sub(0, #k)] then
      return true
    end
  end
  return false
end

--------------------------------------------------------------------------------

local get_dictionary_pattern = function(filename, metamanifest)
  arguments(
      "string", filename,
      "table", metamanifest
    )
  local pattern = { }
  for k, _ in ordered_pairs(metamanifest.dictionary) do
    if filename:find(k, nil, true) then
      pattern[#pattern + 1] = k
    end
  end
  return pattern
end

--------------------------------------------------------------------------------

local break_path = function(path)
  arguments(
      "string", path
    )
  local file_dir_list = { }
  -- TODO: Check if more symbols needed in regexp!!!
  for w in path:gmatch("/[%w%._%-]+") do
    file_dir_list[#file_dir_list + 1] = w:sub(2)
  end
  return file_dir_list
end

--------------------------------------------------------------------------------

local add_to_directory_structure = function(new_file, dir_struct)
  arguments(
      "string", new_file,
      "table", dir_struct
    )
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

--------------------------------------------------------------------------------

local function process_dictionary_recursively(manifest, replaces, return_val, fn, ...)
  for k, v in ordered_pairs(replaces) do
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

--------------------------------------------------------------------------------

-- TODO: move to lua-nucleo #3736
local tifindvalue_nonrecursive = function(pattern, k)
  for i = 1, #pattern do
    if pattern[i] == k then
      return true
    end
  end
  return false
end

--------------------------------------------------------------------------------
-- search dictionary and all used replaces subdictionaries for pattern match

local get_replacement_pattern
do

  -- TODO: consider more clear subdictionary search,
  --       best of all try making single subdictionary searching function
  local function find_patterns_recursively(
      pattern,
      replaces_used,
      manifest,
      filename
    )
    for k, v in ordered_pairs(replaces_used) do
      if manifest.subdictionary[v] then
        for k, _ in ordered_pairs(manifest.subdictionary[v].replicate_data) do
          if filename:find(k, nil, true) and not tifindvalue_nonrecursive(pattern, k) then
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
    for k, _ in ordered_pairs(metamanifest.replicate_data) do
      if filename:find(k, nil, true) then
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

--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------

local get_wrapped_string = function(string_to_process, wrapper)
  local block_top_wrapper =
    wrapper.top.left:gsub("%p", "%%%1") .. string_to_process ..
    wrapper.top.right:gsub("%p", "%%%1")
  local block_bottom_wrapper =
    wrapper.bottom.left:gsub("%p", "%%%1") .. string_to_process ..
    wrapper.bottom.right:gsub("%p", "%%%1")
  return
    block_top_wrapper .. ".-" .. block_bottom_wrapper,
    block_top_wrapper,
    block_bottom_wrapper
end

--------------------------------------------------------------------------------

local cut_wrappers = function(text, wrapper, value)
  local string_to_find, block_top_wrapper, block_bottom_wrapper =
    get_wrapped_string(value, wrapper)
  return text:gsub(block_top_wrapper .. "\n", ""):gsub("\n" .. block_bottom_wrapper, "")
end

local remove_wrappers = function(text, wrapper)
  local string_to_find, block_top_wrapper, block_bottom_wrapper =
    get_wrapped_string('[^{}]-', wrapper)
  return text:gsub(block_top_wrapper .. "\n", ""):gsub("\n" .. block_bottom_wrapper, "")
end

--------------------------------------------------------------------------------

local function find_top_level_blocks(text, wrapper, replaces_used, blocks)
  if replaces_used then
    for k, v in ordered_pairs(replaces_used) do
      text = cut_wrappers(text, wrapper, k)
    end
  end

  blocks = blocks or { }
  local top_wrapper_start, top_left_wrapper_end = text:find(wrapper.top.left, nil, true)
  local top_right_wrapper_start = text:find(wrapper.top.right, nil, true)

  if top_left_wrapper_end and top_right_wrapper_start then
    local val = text:sub(top_left_wrapper_end + 1, top_right_wrapper_start - 1)
    local _, bottom_wrapper_end =
      text:find(wrapper.bottom.left .. val .. wrapper.bottom.right, nil, true)
    blocks[#blocks + 1] =
    {
      value = val;
      text = text:sub(top_wrapper_start, bottom_wrapper_end + 1);
    }
    find_top_level_blocks(
        text:sub(bottom_wrapper_end + 1),
        wrapper,
        replaces_used,
        blocks
      )
  end
  return blocks
end

--------------------------------------------------------------------------------

local create_directory_structure = function(new_files)
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

--------------------------------------------------------------------------------

return
{
  copy_file_force = copy_file_force;
  check_path_ignored = check_path_ignored;
  get_dictionary_pattern = get_dictionary_pattern;
  break_path = break_path;
  add_to_directory_structure = add_to_directory_structure;
  process_dictionary_recursively = process_dictionary_recursively;
  get_replacement_pattern = get_replacement_pattern;
  unify_manifest_dictionary = unify_manifest_dictionary;
  find_top_level_blocks = find_top_level_blocks;
  cut_wrappers = cut_wrappers;
  remove_wrappers = remove_wrappers;
  find_replicate_data = find_replicate_data;
  get_wrapped_string = get_wrapped_string;
  create_directory_structure = create_directory_structure;
}
