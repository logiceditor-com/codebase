--------------------------------------------------------------------------------
-- run.lua: project-create runner
--------------------------------------------------------------------------------

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

  local copy_file_check_force  = function(path_from, path_to)
    create_path_to_file(path_to)
    if not CONFIG[TOOL_NAME].force then
      -- TODO: return false if file already existed
      copy_file_with_flag(path_from, path_to, "-n")
    else
      copy_file_with_flag(path_from, path_to, "-f")
    end
    return true
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

  --copy_files------------------------------------------------------------------

  local check_path_ignored = function(short_path, ignore_paths)
    local ignore = tset(ignore_paths)
    for i = 1, #ignore_paths do
      -- if beginning of the path matches ignore path - it is ignored
      if ignore[string.sub(short_path, 0, #ignore_paths[i])] then
        return true
      end
    end
    return false
  end

  local copy_files = function(metamanifest)
    -- TODO: move to (defaults manifest?) variables, constant path in code is evil
    local template_path = assert(luarocks_show_rock_dir("pk-project-tools.project-templates"))
    template_path = string.sub(template_path, 1, -2) .. "/src/lua/project-templates"
    DEBUG_print("template_path :" .. template_path)

    local all_template_files = find_all_files(template_path, ".*")
    local new_files = { }

    -- string length of common part of all file paths
    local shift = 2 + string.len(template_path)
    DEBUG_print("\27[32mignore\27[0m:\n" .. tpretty(metamanifest.ignore_paths, "  ", 80))
    for i = 1, #all_template_files do
      local short_path = string.sub(all_template_files[i], shift)
      local project_filepath = metamanifest.project_path .. short_path
      if check_path_ignored(short_path, metamanifest.ignore_paths) then
        DEBUG_print("\27[32mPATH IGNORED\27[0m: " .. short_path)
      else
        -- do not overwrite if not flag --force used
        if copy_file_check_force(all_template_files[i], project_filepath) then
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
      metamanifest.processed = {}

      -- TODO: replace this
      for k, v in pairs(metamanifest.replicate_data) do
        metamanifest.replicate_data[#metamanifest.replicate_data + 1] = k
        metamanifest.replicate_data[k] = nil
      end

      for i = 1, #metamanifest.replicate_data do
        local data = metamanifest.replicate_data[i]
        local replicate = metamanifest.dictionary[data]

        -- TODO: good way to clean up numbered part?
        --for j = 1, #metamanifest.replicate_data[data] do
        --end
        metamanifest.replicate_data[data] = { }
        for j = 1, #replicate do
          metamanifest.dictionary[string.sub(data, 1, -2) .. "_" .. j] = replicate[j]
          metamanifest.replicate_data[data][j] = string.sub(data, 1, -2) .. "_" ..  j
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
      local add_string = function(path, pattern, replace)
        assert(
            shell_exec(
                "sed",
                "-i",
                "s/" .. pattern .. "/" .. pattern .. "/p;"
             .. "s/" .. pattern .. "/" .. replace .. "/",
                path
              ) == 0
          )
      end

      local replace_string = function(path, pattern, replace)
        assert(
            shell_exec(
                "sed",
                "-i",
                "s/" .. pattern .. "/" .. replace .. "/",
                path
              ) == 0
          )
      end
--[[
      local get_path_in_file_structure = function(path, file_dir_structure, project_path)

        if path == project_path then
          if file_dir_structure.FLAGS["CHECKED_REPLICATED"] then
            return nil
          end
          file_dir_structure.FLAGS["CHECKED_REPLICATED"] = true
          return file_dir_structure
        end

        local file_dir_list = break_path(string.sub(path, #project_path))
        local dir_struct_curr = file_dir_structure
        for j = 1, #file_dir_list do
          if not dir_struct_curr[ file_dir_list[j] ] then
            return nil
          end
          dir_struct_curr = dir_struct_curr[ file_dir_list[j] ]
        end

        if dir_struct_curr.FLAGS["CHECKED_REPLICATED"] then
          return nil
        end
        dir_struct_curr.FLAGS["CHECKED_REPLICATED"] = true
        return dir_struct_curr

      end
--]]
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
        --  assert(file_dir_structure.FLAGS.FILE == nil, "dir structure sanity check")
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
          -- DEBUG_print(created_path .. " FILE \27[32mproject-created, processing\27[0m")
          if filepath ~= created_path then
            copy_file_check_force(filepath, created_path)
          end
          -- TODO: check if pattern exists in file
          -- replace universal pattern to replicated
          for k, v in pairs(replaces_used) do
            replace_string_in_file(
                created_path,
                metamanifest.data_wrapper.left .. k .. metamanifest.data_wrapper.right,
                metamanifest.data_wrapper.left .. v .. metamanifest.data_wrapper.right
              )
          end
          for k, v in pairs(metamanifest.replicate_data) do
            -- TODO: replicate blocks here!
            -- magic that makes "some string SOME_PATTERN" :
            -- "some string val1"
            -- "some string val2"
            -- based on simple sed commands
            for i = 1, (#v - 1) do
              add_string(
                  created_path,
                  metamanifest.data_wrapper.left .. k .. metamanifest.data_wrapper.right,
                  metamanifest.data_wrapper.left .. v[i] .. metamanifest.data_wrapper.right
                )
            end
            replace_string(
                  created_path,
                  metamanifest.data_wrapper.left .. k .. metamanifest.data_wrapper.right,
                  metamanifest.data_wrapper.left .. v[#v] .. metamanifest.data_wrapper.right
                )
          end
        end
      end

      process_replication_recursively = function(
          path_data,
          metamanifest
        )
        for filename, structure in pairs(path_data.existed_structure) do
          if filename ~= "FLAGS" then
            DEBUG_print(path_data.existed_path .. "/" .. filename .. " : \27[32mprocessing\27[0m")
            local filepath = path_data.existed_path .. "/" .. filename
            local attr = lfs.attributes(filepath)
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
                  path_data.created_path .. "/"
               .. pattern_combinations[i].filename
                local replaces_used = tclone(pattern_combinations[i].replaces_used)
                -- local structure_replicated = tclone(structure)
                -- file_dir_structure[pattern_combinations[i].filename] = structure_replicated
                -- structure_replicated.FLAGS["REPLACES"] = replaces_used
                -- structure_replicated.FLAGS["CHECKED_REPLICATED"] = true
                -- Do not enter replcated structure
                -- structure.FLAGS["CHECKED_REPLICATED"] = true

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
                    path_data.created_structure[filename]
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
      DEBUG_print("Making plain dictionary")
      metamanifest = make_plain_dictionary(metamanifest)
      DEBUG_print("\27[32mmetamanifest\27[0m :" .. tpretty(metamanifest, "  ", 80))

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
        local attr = assert(lfs.attributes(filepath))

        -- TODO: replace on reading file_dir_structure FLAGS?
        local pattern_used = get_replacement_pattern(filename, metamanifest)

        if #pattern_used > 0 then
          DEBUG_print("\27[31mremoving\27[0m: " .. filepath)
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

  --fill_placeholders-----------------------------------------------------------

  local fill_placeholders
  do
    local replace_dictionary_patterns = function(filepath, metamanifest)
      local new_filepath = filepath
      for k, v in pairs(metamanifest.dictionary) do
        if new_filepath:find(k) then
          new_filepath = string.gsub(new_filepath, k, v);
        end
      end
      -- TODO: vaible way?
      if filepath ~= new_filepath then
        -- TODO: use os.fileexists(new_filepath) on non force renaming?
        local res, err = os.rename(filepath, new_filepath)
        if res == nil then
          if not CONFIG[TOOL_NAME].force then
            DEBUG_print(
                "\27[31mcan't rename\27[0m: " .. err
              )
            remove_recursively(filepath)
            DEBUG_print("removed")
          else
            remove_recursively(new_filepath)
            assert(os.rename(filepath, new_filepath))
            DEBUG_print(
                "\27[32mforce renamed\27[0m: \n   " .. filepath
             .. "\nto " .. new_filepath)
          end
        else
          DEBUG_print("\27[32mrenamed\27[0m: \n   " .. filepath .. "\nto " .. new_filepath)
        end
      end
      --copy_file_check_force(all_template_files[i], new_filename)
      return new_filepath
    end


    local replace_dictionary_in_file = function(filename, metamanifest)
      for k, v in pairs(metamanifest.dictionary) do
        replace_string_in_file(
            filename,
            metamanifest.data_wrapper.left .. k .. metamanifest.data_wrapper.right,
            v
          )
      end
    end

    fill_placeholders = function(
        metamanifest, path, file_dir_structure
      )
      for filename, structure in pairs(file_dir_structure) do
        if filename ~= "FLAGS" then
          local filepath = path .. "/" .. filename
          DEBUG_print(filepath .. " : \27[32mprocessing\27[0m")
          filepath = replace_dictionary_patterns(filepath, metamanifest)
          local attr = lfs.attributes(filepath)
          if attr.mode == "directory" then
            fill_placeholders(metamanifest, filepath, structure)
          else
            -- replace dictionary patterns
            replace_dictionary_in_file(filepath, metamanifest)
          end

        end -- if filename ~= "." and filename ~= ".." and filename ~= ".git" then
      end -- for filename in lfs.dir(path_data.existed_path) do
    end
  end

  ------------------------------------------------------------------------------
  --[[ not used
  local chmod_bin
  do
    local chmod_files = function(bin_path)
     for filename in lfs.dir(bin_path) do
        if filename ~= "." and filename ~= ".." and filename ~= ".git" then
          local filepath = bin_path .. "/" .. filename
          local attr = lfs.attributes(filepath)
          if attr.mode == "directory" then
            chmod_files(filepath)
          else
            DEBUG_print("Chmodding " .. filepath .. " 755")
            assert(shell_exec("sudo", "chmod", "755", filepath) == 0)
          end
        end -- if filename ~= "." and filename ~= ".." and filename ~= ".git" then
      end -- for filename in lfs.dir(path_data.existed_path) do
    end

    chmod_bin = function(project_path)
      for filename in lfs.dir(project_path) do
        if filename ~= "." and filename ~= ".." and filename ~= ".git" then
          local filepath = project_path .. "/" .. filename
          local attr = lfs.attributes(filepath)
          if attr.mode == "directory" then
            if filename == "bin" then
              chmod_files(filepath)
            else
              chmod_bin(filepath)
            end
          elseif filename == "gen-rockspec" or filename == "gen-rockspecs" then
            DEBUG_print("Chmodding " .. filepath .. " 755")
            assert(shell_exec("sudo", "chmod", "755", filepath) == 0)
          end
        end -- if filename ~= "." and filename ~= ".." and filename ~= ".git" then
      end -- for filename in lfs.dir(path_data.existed_path) do
    end
  end
  --]]
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
    DEBUG_print("Loading defaults")

    -- TODO: HACK? how to get path to this?
    local defaults_path = 
      assert(luarocks_show_rock_dir("pk-project-tools.pk-project-create"))
    defaults_path =
      string.sub(defaults_path, 1, -2) .. "/src/lua/project-create/metamanifest"
    local metamanifest_defaults = load_project_manifest(defaults_path, "", "")
    DEBUG_print(
        "\27[32mmetamanifest defaults\27[0m:"
     .. tpretty(metamanifest_defaults, "  ", 80)
      )

    DEBUG_print("Loading project metamanifest")
    local metamanifest = load_project_manifest(
        metamanifest_path,
        project_path,
        ""
      )
    DEBUG_print(
        "\27[32mproject metamanifest\27[0m:"
     .. tpretty(metamanifest, "  ", 80)
      )
    metamanifest = twithdefaults(metamanifest, metamanifest_defaults)
    metamanifest.project_path = project_path
    DEBUG_print("\27[32mfinal metamanifest\27[0m:" .. tpretty(metamanifest, "  ", 80))

    DEBUG_print("\n\n")
    log("\27[1mCopy template files\27[0m")
    local new_files = copy_files(metamanifest)
    DEBUG_print("new files :" .. tpretty(new_files, "  ", 80))
    local file_dir_structure = create_directory_structure(new_files)
    DEBUG_print("file_dir_structure :" .. tpretty(file_dir_structure, "  ", 80))
    local clean_up_data = tclone(file_dir_structure)

    DEBUG_print("\n\n")
    log("\27[1mReplicating data\27[0m")
    local replicated_structure = replicate_data(metamanifest, file_dir_structure)
    DEBUG_print("replicated_structure :" .. tpretty(replicated_structure, "  ", 80))

    DEBUG_print("\n\n")
    log("\27[1mCleanup replication data\27[0m")
    -- TODO: file_dir_structure =
    clean_up_replicate_data_recursively(
        metamanifest,
        metamanifest.project_path,
        clean_up_data
      )

    DEBUG_print("\n\n")
    log("\27[1mFilling placeholders\27[0m")
    -- TODO: file_dir_structure =
    fill_placeholders(
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
        param.force             = args["--force"]
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
