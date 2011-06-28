  --------------------------------------------------------------------------------
-- run.lua: project-create runner
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
      tset
      = import 'lua-nucleo/table-utils.lua'
      {
        'tgetpath',
        'tclone',
        'twithdefaults',
        'tset'
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

local tpretty = import 'lua-nucleo/tpretty.lua' { 'tpretty' }

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

  local get_replacement_pattern = function(filename, metamanifest)
    local pattern = { }
    for k, _ in pairs(metamanifest.replicate_data) do
      if filename:find(k) then
        pattern[#pattern + 1] = k
      end
    end
    return pattern
  end

  local replace_string_in_file = function(filename, string, replace)
    -- TODO: check on '/' and replace to s||| or s:::
    DEBUG_print("string :", string)
    DEBUG_print("replace :", replace)
    if type(replace) == "table" then DEBUG_print("\27[32mreplace\27[0m:\n" .. tpretty(replace, "  ", 80)) end
    assert(
        shell_exec(
            "sed",
            "-i",
            "s/" .. string .. "/" .. replace .. "/g",
            filename
          ) == 0
      )
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
  
  -- replicate ignored paths ---------------------------------------------------

  local process_ignored_paths = function(metamanifest)
    local ignored = tset(metamanifest.ignore_paths)
    for ignore, _ in pairs(ignored) do
      for k, v in pairs(metamanifest.dictionary) do
        if is_table(v) then
          for j = 1, #v do
            if not ignored[string.gsub(ignore, string.gsub(k, "%p", "%%%1"), v[j])] then
              ignored[string.gsub(ignore, string.gsub(k, "%p", "%%%1"), v[j])] = true
              ignored[ignore] = nil
            end
          end
        elseif v == false then
          if not ignored[string.gsub(ignore, string.gsub(k, "%p", "%%%1"), "")] then
            ignored[ignore] = nil
          end
        else
          if not ignored[string.gsub(ignore, string.gsub(k, "%p", "%%%1"), v)] then
            ignored[string.gsub(ignore, string.gsub(k, "%p", "%%%1"), v)] = true
            ignored[ignore] = nil
          end
        end
      end
    end
    metamanifest.ignore_paths = ignored
    --DEBUG_print("\27[32mmetamanifest.ignored\27[0m: \n " .. tpretty(metamanifest.ignore_paths, "  ", 80))
    return metamanifest
  end

  --copy_files------------------------------------------------------------------

  local copy_files = function(metamanifest)
    -- TODO: move to (defaults manifest?) variables, constant path in code is evil
    local template_path = assert(luarocks_show_rock_dir("pk-project-tools.project-templates"))
    template_path = string.sub(template_path, 1, -2) .. "/src/lua/project-templates"
    DEBUG_print("\27[37mTemplate_path:\27[0m " .. template_path)

    local all_template_files = find_all_files(template_path, ".*")
    local new_files = { }

    -- string length of common part of all file paths
    local shift = 2 + string.len(template_path)
    DEBUG_print("\27[33mDo not overwrite in\27[0m:")
    for k, v in pairs(metamanifest.ignore_paths) do
      DEBUG_print("  " .. k)
    end
    for i = 1, #all_template_files do
      local short_path = string.sub(all_template_files[i], shift)
      local project_filepath = metamanifest.project_path .. "/" .. short_path
      if
        check_path_ignored(short_path, metamanifest.ignore_paths) 
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

  --replicate_data--------------------------------------------------------------

  local replicate_data
  do
    local make_plain_dictionary = function(metamanifest)
      metamanifest.processed = { }

      metamanifest.replicate_data = { }
      for k, v in pairs(metamanifest.dictionary) do
        if is_table(v) then
          metamanifest.replicate_data[#metamanifest.replicate_data + 1] = k
        end
      end
      
      metamanifest.subdictionary = { }
      for i = 1, #metamanifest.replicate_data do
        local data = metamanifest.replicate_data[i]
        local replicate = metamanifest.dictionary[data]
        --DEBUG_print("\27[32mdata\27[0m:\n" .. data)
        --DEBUG_print("\27[32mmetamanifest.dictionary[data]\27[0m:\n"
        --.. tpretty(metamanifest.dictionary[data], "  ", 80))
        -- TODO: good way to clean up numbered part?
        --for j = 1, #metamanifest.replicate_data[data] do
        --end
        metamanifest.replicate_data[data] = { }
        for j = 1, #replicate do
          metamanifest.dictionary[string.sub(data, 1, -2) .. "_" .. j] = replicate[j]
          metamanifest.replicate_data[data][j] = string.sub(data, 1, -2) .. "_" ..  j
          metamanifest.subdictionary[string.sub(data, 1, -2) .. "_" .. j] = replicate[replicate[j]]
        end
        metamanifest.processed[data] = tclone(metamanifest.dictionary[data])
        metamanifest.dictionary[data] = nil
        metamanifest.replicate_data[i] = nil
      end
      return metamanifest
    end
    
    local process_pattern_combination = function(pattern, filenames, metamanifest)
      local new_filenames = { }
      for i = 1, #filenames do
        local replacements = { }
        if filenames[i].replaces_used[pattern] ~= nil then
          replacements[1] = filenames[i].replaces_used[pattern]
        else
          replacements = metamanifest.replicate_data[pattern]
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
      local replace_dictionary_in_string = function(
          string_to_process,
          dictionary,
          data_wrapper
        )
        for k, v in pairs(dictionary) do
          if is_string(v) then
            -- TODO: hack?
            local to_insert = string.gsub(v, "%%", "%%%1")
            string_to_process = string.gsub(
                string_to_process,
                string.gsub(data_wrapper.left, "%p", "%%%1")
             .. string.gsub(k, "%p", "%%%1")
             .. string.gsub(data_wrapper.right, "%p", "%%%1"),
                to_insert
              )
           -- Remove all strings with pattern that ==false
           elseif v == false then
DEBUG_print("String before: " .. string_to_process)
            string_to_process = string.gsub(
                string_to_process,
                "\n[.]*"
             .. string.gsub(data_wrapper.left, "%p", "%%%1")
             .. string.gsub(k, "%p", "%%%1")
             .. string.gsub(data_wrapper.right, "%p", "%%%1")
             .. "[.]*\n",
                "\n"
              )
DEBUG_print("String before: " .. string_to_process)
           else
             assert(nil, k .. " is not string or false in manifest dictionary")
           end
        end
        return string_to_process
      end
    
      local replicate_and_replace_in_file = function(
          metamanifest,
          created_dir_structure,
          replaces_used,
          created_path
        )
        -- TODO: check if pattern exists in file
        local block = metamanifest.block_wrapper
        local file = assert(io.open(created_path, "r"))
        local file_content = file:read("*all")
        file:close()
        -- replace patterns already fixed for this file
        for k, v in pairs(replaces_used) do
          file_content = string.gsub(
              file_content,
              metamanifest.data_wrapper.left .. k .. metamanifest.data_wrapper.right,
              metamanifest.data_wrapper.left .. v .. metamanifest.data_wrapper.right
            )
          if metamanifest.subdictionary[metamanifest.dictionary[v]] then
            file_content = replace_dictionary_in_string(
                file_content,
                metamanifest.subdictionary[metamanifest.dictionary[v]],
                metamanifest.data_wrapper
              )
          end
        end
        -- replicate blocks
        local current_block_replica = ""
        local blocks = {}
        for k, v in pairs(metamanifest.replicate_data) do
          -- TODO: replicate blocks here! Almost done!
          --find block
          local block_top_wrapper = 
            string.gsub(block.top_left, "%p", "%%%1") .. k ..
            string.gsub(block.top_right, "%p", "%%%1")
          local block_bottom_wrapper =
            string.gsub(block.bottom_left, "%p", "%%%1") .. k ..
            string.gsub(block.bottom_right, "%p", "%%%1")
          local string_to_find =
            block_top_wrapper .. ".-" .. block_bottom_wrapper
          blocks = {}
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
                  string.gsub(metamanifest.data_wrapper.left, "%p", "%%%1")
               .. k
               .. string.gsub(metamanifest.data_wrapper.right, "%p", "%%%1"),
                  metamanifest.data_wrapper.left .. v[i] .. metamanifest.data_wrapper.right
                )
              -- sub dictionary replaces
              if metamanifest.subdictionary[v[i]] then
                current_block_replica = replace_dictionary_in_string(
                    current_block_replica,
                    metamanifest.subdictionary[v[i]],
                    metamanifest.data_wrapper
                  )
              end
              -- cut block wrappers
              current_block_replica = string.gsub(current_block_replica, block_top_wrapper .. "\n", "")
              current_block_replica = string.gsub(current_block_replica, "\n" .. block_bottom_wrapper, "")
              blocks_set_to_write[j][i] = current_block_replica
            end
            --replace found block
            file_content = string.gsub(
                file_content,
                string.gsub(blocks[j], "[%p%%]", "%%%1"),
                table.concat(blocks_set_to_write[j], "\n")
              )
          end         
          --DEBUG_print("\27[32mBlock replicas\27[0m:" .. tpretty(blocks_set_to_write, "  ", 80))
        end

        -- TODO: remove code duplication
        -- removing blocks with "false" dictionary patterns
        for k, v in pairs(metamanifest.dictionary) do
          if v == false then
            --find block
            local block_top_wrapper = 
              string.gsub(block.top_left, "%p", "%%%1") .. k ..
              string.gsub(block.top_right, "%p", "%%%1")
            local block_bottom_wrapper =
              string.gsub(block.bottom_left, "%p", "%%%1") .. k ..
              string.gsub(block.bottom_right, "%p", "%%%1")
            local string_to_find =
              block_top_wrapper .. ".-" .. block_bottom_wrapper
            blocks = {}
            for w in string.gmatch(file_content, string_to_find) do
              blocks[#blocks + 1] = w
            end
            for j = 1, #blocks do
            --remove found block
DEBUG_print("Before block removed: " .. file_content)
              file_content = string.gsub(
                  file_content,
                  string.gsub(blocks[j], "[%p%%]", "%%%1"),
                  "\n"
                )
DEBUG_print("After block removed: " .. file_content)
            end
          end
        end

        file_content = replace_dictionary_in_string(
            file_content,
            metamanifest.dictionary,
            metamanifest.data_wrapper
          )
        --DEBUG_print(file_content)
        local file = io.open(created_path, "w")
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
            DEBUG_print("\27[32mCopy to:\27[0m " .. string.sub(created_path, #metamanifest.project_path + 2))
            copy_file_force(filepath, created_path)
          end
          replicate_and_replace_in_file(metamanifest, created_dir_structure, replaces_used, created_path)
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
            local pattern_used = get_replacement_pattern(filename, metamanifest)

            -- filename have patterns to replicate
            if #pattern_used > 0 then
              --DEBUG_print("FILENAME: ", filename)
              --DEBUG_print("  pattern used: ", tpretty(pattern_used, "  ", 80))
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
              --DEBUG_print("  pattern combinations: ", tpretty(pattern_combinations, "  ", 80))
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

    replicate_data = function(
        metamanifest,
        file_dir_structure
      )
      metamanifest = make_plain_dictionary(metamanifest)
      DEBUG_print("\27[32mPlain dictionary:\27[0m \n" .. tpretty(metamanifest.dictionary, "  ", 80))
      DEBUG_print("\27[32mSubdictionaries :\27[0m \n" .. tpretty(metamanifest.subdictionary, "  ", 80))

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
    --for filename in lfs.dir(path) do
--    DEBUG_print("\27[31mpath\27[0m".. path)
--    DEBUG_print("file_dir_structure :" .. tpretty(file_dir_structure, "  ", 80))
    for filename, structure in pairs(file_dir_structure) do
      if filename ~= "FLAGS" then
--        DEBUG_print("\27[31mfilename\27[0m" .. filename)
--        DEBUG_print("structure :" .. tpretty(structure, "  ", 80))
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
    local replace_dictionary_patterns_in_path = function(filepath, metamanifest)
      local new_filepath = filepath
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
        else
          create_path_to_file(new_filepath)
          assert(os.rename(filepath, new_filepath), filepath .. " -> " .. new_filepath)
          DEBUG_print("\27[33mRenamed:\27[0m " .. short_path_new)
        end
      end
--      return new_filepath
    end

    fill_placeholders = function(
        metamanifest, path, file_dir_structure
      )
      metamanifest.cleanup = { }
      for filename, structure in pairs(file_dir_structure) do
        if filename ~= "FLAGS" then
          local filepath = path .. "/" .. filename
          DEBUG_print("\27[32mProcess:\27[0m " .. string.sub(filepath, #metamanifest.project_path + 2))
          --filepath = replace_dictionary_patterns_in_path(filepath, metamanifest)
          local attr = lfs.attributes(filepath)
          if attr.mode == "directory" then
            fill_placeholders(metamanifest, filepath, structure)
          else
            replace_dictionary_patterns_in_path(filepath, metamanifest)
          end
        end
      end
    end
  end

  --clean_up_replicate_data-----------------------------------------------------

  local function clean_up_generated_data_recursively(metamanifest, path, file_dir_structure)
    for filename, structure in pairs(file_dir_structure) do
      if filename ~= "FLAGS" then
        local filepath = path .. "/" .. filename
        
        -- TODO: BAD handle through dir structure
        if does_file_exist(filepath) then
          local attr = assert(lfs.attributes(filepath))

          -- TODO: replace on reading file_dir_structure FLAGS?
          local pattern_used = get_dictionary_pattern(filename, metamanifest)

          if #pattern_used > 0 then
            DEBUG_print("\27[33mRemoved: " .. string.sub(filepath, #metamanifest.project_path + 2) .. "\27[0m")
            remove_recursively(filepath)
          else
            local attr = assert(lfs.attributes(filepath))
            if attr.mode == "directory" then
              DEBUG_print("\27[32mChecked:\27[0m " .. string.sub(filepath, #metamanifest.project_path + 2))
              clean_up_generated_data_recursively(metamanifest, filepath, structure)
            end
          end
        end
      end

    end
  end

  ------------------------------------------------------------------------------
  create_project = function(
      metamanifest_path,
      project_path
    )
    arguments(
        "string", metamanifest_path,
        "string", project_path
      )

    log("\27[1mLoading metamanifest\27[0m")

    -- TODO: HACK? how to get path to this?
    local defaults_path = 
      assert(luarocks_show_rock_dir("pk-project-tools.pk-project-create"))
    defaults_path =
      string.sub(defaults_path, 1, -2) .. "/src/lua/project-create/metamanifest"
    local metamanifest_defaults = load_project_manifest(defaults_path, "", "")
    local metamanifest_project = load_project_manifest(
        metamanifest_path,
        project_path,
        ""
      )
    local metamanifest = twithdefaults(metamanifest_project, metamanifest_defaults)
    metamanifest.project_path = project_path
    
    DEBUG_print("\27[32mDefault metamanifest:\27[0m\n" .. tpretty(metamanifest_defaults, "  ", 80))
    DEBUG_print("\27[32mProject metamanifest:\27[0m\n" .. tpretty(metamanifest_project, "  ", 80))
    DEBUG_print("\27[32mFinal metamanifest:\27[0m\n" .. tpretty(metamanifest, "  ", 80))

    metamanifest = process_ignored_paths(metamanifest)

    log("\27[1mCopy template files\27[0m")
    local new_files = copy_files(metamanifest)
    --DEBUG_print("new files :" .. tpretty(new_files, "  ", 80))
    local file_dir_structure = create_directory_structure(new_files)
    --DEBUG_print("file_dir_structure :" .. tpretty(file_dir_structure, "  ", 80))
    local clean_up_data = tclone(file_dir_structure)

    log("\27[1mReplicating data\27[0m")
    local replicated_structure = replicate_data(metamanifest, file_dir_structure)
    -- TODO: make some more nice dir structure output?
    -- DEBUG_print("replicated_structure :" .. tpretty(replicated_structure, "  ", 80))

    log("\27[1mCleanup replication data\27[0m")
    -- TODO: file_dir_structure =
    clean_up_replicate_data_recursively(
        metamanifest,
        metamanifest.project_path,
        clean_up_data
      )

    log("\27[1mFilling placeholders\27[0m")
    -- TODO: file_dir_structure =
    fill_placeholders(
        metamanifest,
        metamanifest.project_path,
        replicated_structure
      )

    log("\27[1mCleanup generated data\27[0m")
    clean_up_generated_data_recursively(
        metamanifest,
        metamanifest.project_path,
        replicated_structure
      )

    log("\27[1mProject " .. metamanifest.dictionary.PROJECT_NAME .. " created\27[0m")
    return true
  end
end

--------------------------------------------------------------------------------

local EXTRA_HELP = [[

pk-project-create: fast project creation tool

Usage:

    pk-project-create <metamanifest_directory_path> <project_root_dir> [options]

Options:

    --debug                    Verbose output
    --force                    Force overwrite all generated files over old copies
]]

local CONFIG_SCHEMA = create_config_schema()

--------------------------------------------------------------------------------

local run = function(...)
  -- WARNING: Action-less tool. Take care when copy-pasting.

  CONFIG, ARGS = load_tools_cli_config(
      function(args) -- Parse actions
        local param = { }

        param.metamanifest_path = args[1]
        param.root_project_path = args[2]
        param.debug             = args["--debug"]
        param.force             = true --args["--force"]
        return
        {
          PROJECT_PATH = ""; -- TODO: Remove
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

  ------------------------------------------------------------------------------

  create_project(
      CONFIG[TOOL_NAME].metamanifest_path,
      CONFIG[TOOL_NAME].root_project_path
    )
end

return
{
  run = run;
}
