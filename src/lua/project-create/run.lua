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

local shell_read,
      shell_exec
      = import 'lua-aplicado/shell.lua'
      {
        'shell_read',
        'shell_exec'
      }

local do_in_environment,
      make_config_environment
      = import 'lua-nucleo/sandbox.lua'
      {
        'do_in_environment',
        'make_config_environment'
      }

local tgetpath,
      tclone
      = import 'lua-nucleo/table-utils.lua'
      {
        'tgetpath',
        'tclone'
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

  local copy_file = function(path_from, path_to)
    assert(create_path_to_file(path_to))
    assert(
        write_file(
            path_to,
            assert(read_file(path_from))
          )
      )
  end

  local copy_if_not_exist  = function(path_from, path_to)
    if not does_file_exist(path_to) then
      DEBUG_print("copy file :" .. path_from)
      copy_file(path_from, path_to)
      return true
    else
      DEBUG_print("\27[31mfile already exists\27[0m :" .. path_to)
      return false
    end
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
    assert(
        shell_exec(
            "sed",
            "-i",
            "s/" .. string .. "/" .. replace .. "/g",
            filename
          ) == 0
      )
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

  local function remove_recursively(path)
    local attr = assert(lfs.attributes(path))
    if attr.mode == "directory" then
      for filename in lfs.dir(path) do
        if filename ~= "." and filename ~= ".." and filename ~= ".git" then
          local filepath = path .. "/" .. filename
          remove_recursively(filepath)
        end
      end
    end
    os.remove(path)
  end

  --copy_files------------------------------------------------------------------

  local copy_files = function(project_path)
    -- TODO: move to (defaults manifest?) variables, constant path in code is evil
    local template_path = assert(luarocks_show_rock_dir("pk-project-tools.project-templates"))
    template_path = string.sub(template_path, 1, -2) .. "/src/lua/project-templates"
    DEBUG_print("template_path :" .. template_path)

    local all_template_files = find_all_files(template_path, ".*")
    local new_files = { }

    -- string length of common part of all file paths
    local shift = 2 + string.len(template_path)

    for i = 1, #all_template_files do
      local short_path = string.sub(all_template_files[i], shift)
      local project_filepath = project_path .. short_path

      -- do not overwrite
      if copy_if_not_exist(all_template_files[i], project_filepath) then
        new_files[#new_files + 1] = short_path
      end
    end

    return new_files
  end

  --replicate_data--------------------------------------------------------------

  local replicate_data
  do
    local make_plain_dictionary = function(metamanifest)
      metamanifest.processed = {}
      for i = 1, #metamanifest.replicate_data do
        local data = metamanifest.replicate_data[i]
        local replicate = metamanifest.dictionary[data]
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

      local process_curr_path = function(
          attr, created_path, filepath, replaces_used, metamanifest
        )
        if attr.mode == "directory" then
          create_path_to_file(created_path .. "/.")
          DEBUG_print("dir checked: ", created_path)
          process_replication_recursively(
             {
               existed_path = filepath,
               created_path = created_path,
               replaces_used = replaces_used
             },
             metamanifest
           )
        else
          if filepath ~= created_path then
            copy_if_not_exist(filepath, created_path)
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

      process_replication_recursively = function(path_data, metamanifest)
        if path_data.existed_path ~= path_data.created_path then
          DEBUG_print("\nPATH DATA: ", tpretty(path_data, "  ", 80))
        end
        for filename in lfs.dir(path_data.existed_path) do
          if filename ~= "." and filename ~= ".." and filename ~= ".git" then
            local filepath = path_data.existed_path .. "/" .. filename
            local attr = lfs.attributes(filepath)
            local pattern_used = get_replacement_pattern(filename, metamanifest)

            -- filename have patterns to replicate
            if #pattern_used > 0 then
              DEBUG_print("FILENAME: ", filename)
              DEBUG_print("  pattern used: ", tpretty(pattern_used, "  ", 80))
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
              DEBUG_print("  pattern combinations: ", tpretty(pattern_combinations, "  ", 80))
              for i = 1, #pattern_combinations do
                -- create paths
                local created_path =
                  path_data.created_path .. "/"
               .. pattern_combinations[i].filename
                local replaces_used = tclone(pattern_combinations[i].replaces_used)
                -- recursion hided here
                process_curr_path(
                    attr, created_path, filepath, replaces_used, metamanifest
                  )
              end

            -- filename has no patterns to replicate
            else
              local created_path = path_data.created_path .. "/" .. filename
              local replaces_used = tclone(path_data.replaces_used)
              -- recursion hided here
              process_curr_path(
                  attr, created_path, filepath, replaces_used, metamanifest
                )
            end

          end -- if filename ~= "." and filename ~= ".." and filename ~= ".git" then
        end -- for filename in lfs.dir(path_data.existed_path) do
      end -- process_replication_recursively
    end -- do

    replicate_data = function(
        metamanifest,
        project_path
      )
      DEBUG_print("Making plain dictionary")
      metamanifest = make_plain_dictionary(metamanifest)
      DEBUG_print("metamanifest :" .. tpretty(metamanifest, "  ", 80))

      -- no dictionary replacements
      process_replication_recursively(
          {
            existed_path = project_path,
            created_path = project_path,
            replaces_used = { }
          },
          metamanifest
        )
    end
  end

  --clean_up_replicate_data-----------------------------------------------------

  local clean_up_replicate_data
  do
    clean_up_replicate_data = function(metamanifest, path)
      for filename in lfs.dir(path) do
        if filename ~= "." and filename ~= ".." and filename ~= ".git" then
          local filepath = path .. "/" .. filename
          local attr = assert(lfs.attributes(filepath))
          local pattern_used = get_replacement_pattern(filename, metamanifest)
          if #pattern_used > 0 then
            DEBUG_print("removing: " .. filepath)
            remove_recursively(filepath)
          else
            local attr = assert(lfs.attributes(filepath))
            if attr.mode == "directory" then
              clean_up_replicate_data(metamanifest, filepath)
            end
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
        local res, err = os.rename(filepath, new_filepath)
        if res == nil then
          DEBUG_print(
              "\27[31mcan't rename\27[0m: " .. err
            )
          remove_recursively(filepath)
          DEBUG_print("removed")
        else
          DEBUG_print("renamed: \n   " .. filepath .. "\nto " .. new_filepath)
        end
      end
      --copy_if_not_exist(all_template_files[i], new_filename)
      return new_filepath
    end

    fill_placeholders = function(
        metamanifest,
        project_path
      )
      for filename in lfs.dir(project_path) do
        if filename ~= "." and filename ~= ".." and filename ~= ".git" then
          local filepath = project_path .. "/" .. filename
          filepath = replace_dictionary_patterns(filepath, metamanifest)
          local attr = lfs.attributes(filepath)
          if attr.mode == "directory" then
            fill_placeholders(metamanifest, filepath)
          else
            -- replace dictionary patterns
            replace_dictionary_in_file(filepath, metamanifest)
          end

        end -- if filename ~= "." and filename ~= ".." and filename ~= ".git" then
      end -- for filename in lfs.dir(path_data.existed_path) do
    end
  end

  ------------------------------------------------------------------------------
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


  ------------------------------------------------------------------------------

  local run_scripts = function(
      metamanifest,
      project_path
    )
    DEBUG_print("run_scripts NYI")
  end

  ------------------------------------------------------------------------------
  -- TODO: ignore lib dir
  create_project = function(
      metamanifest_path,
      project_path
    )
    arguments(
        "string", metamanifest_path,
        "string", project_path
      )

    DEBUG_print("\n\n\27[1mLoading metamanifest\27[0m")
    local metamanifest = load_project_manifest(
        metamanifest_path,
        project_path,
        ""
      )
    DEBUG_print("metamanifest :" .. tpretty(metamanifest, "  ", 80))

    -- TODO: handle overwriting with flag, now overwriting is prohibited
    DEBUG_print("\n\n\27[1mCopy template files\27[0m")
    local new_files = copy_files(project_path)
    DEBUG_print("new files :" .. tpretty(new_files, "  ", 80))

    DEBUG_print("\n\n\27[1mReplicating data\27[0m")
    replicate_data(metamanifest, project_path)

    DEBUG_print("\n\n\27[1mCleanup replication data\27[0m")
    clean_up_replicate_data(metamanifest, project_path)

    DEBUG_print("\n\n\27[1mFilling placeholders\27[0m")
    fill_placeholders(metamanifest, project_path)

    -- TODO: WRONG, copy chmod from template
    DEBUG_print("\n\n\27[1mChmodding\27[0m")
    chmod_bin(project_path)

    DEBUG_print("\n\n\27[1mRun project generative and deployment scripts\27[0m")
    run_scripts(metamanifest, project_path)

    log("project created")
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
