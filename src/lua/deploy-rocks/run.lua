local log, dbg, spam, log_error
      = import 'pk-core/log.lua' { 'make_loggers' } (
          "deploy-rocks", "DRO"
        )

--------------------------------------------------------------------------------

local pairs, pcall, assert, error, select, next, loadfile, loadstring
    = pairs, pcall, assert, error, select, next, loadfile, loadstring

local table_concat = table.concat

local io = io
local os = os

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

local is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_table'
      }

local assert_is_table,
      assert_is_string
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table',
        'assert_is_string'
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

local tset,
      timapofrecords,
      twithdefaults,
      tkeys,
      tclone
      = import 'lua-nucleo/table-utils.lua'
      {
        'tset',
        'timapofrecords',
        'twithdefaults',
        'tkeys',
        'tclone'
      }

local fill_curly_placeholders,
      trim
      = import 'lua-nucleo/string.lua'
      {
        'fill_curly_placeholders',
        'trim'
      }

local do_in_environment
      = import 'lua-nucleo/sandbox.lua'
      {
        'do_in_environment'
      }

local make_checker
      = import 'lua-nucleo/checker.lua'
      {
        'make_checker'
      }

local write_file,
      read_file,
      find_all_files,
      does_file_exist,
      splitpath,
      get_filename_from_path
      = import 'lua-aplicado/filesystem.lua'
      {
        'write_file',
        'read_file',
        'find_all_files',
        'does_file_exist',
        'splitpath',
        'get_filename_from_path'
      }

local shell_exec,
      shell_read,
      shell_exec_no_subst,
      shell_read_no_subst,
      shell_format_command,
      shell_format_command_no_subst
      = import 'lua-aplicado/shell.lua'
      {
        'shell_exec',
        'shell_read',
        'shell_exec_no_subst',
        'shell_read_no_subst',
        'shell_format_command',
        'shell_format_command_no_subst'
      }

local shell_exec_remote,
      shell_read_remote
      = import 'lua-aplicado/shell/remote.lua'
      {
        'shell_exec_remote',
        'shell_read_remote'
      }

local git_format_command,
      git_exec,
      git_read,
      git_get_tracking_branch_name_of_HEAD,
      git_update_index,
      git_is_dirty,
      git_is_directory_dirty,
      git_has_untracked_files,
      git_are_branches_different,
      git_is_file_changed_between_revisions,
      git_add_directory,
      git_commit_with_message,
      git_push_all
      = import 'lua-aplicado/shell/git.lua'
      {
        'git_format_command',
        'git_exec',
        'git_read',
        'git_get_tracking_branch_name_of_HEAD',
        'git_update_index',
        'git_is_dirty',
        'git_is_directory_dirty',
        'git_has_untracked_files',
        'git_are_branches_different',
        'git_is_file_changed_between_revisions',
        'git_add_directory',
        'git_commit_with_message',
        'git_push_all'
      }

local luarocks_exec,
      luarocks_exec_no_sudo,
      luarocks_exec_dir,
      luarocks_admin_exec_dir,
      luarocks_remove_forced,
      luarocks_ensure_rock_not_installed_forced,
      luarocks_make_in,
      luarocks_exec_dir_no_sudo,
      luarocks_pack_to,
      luarocks_admin_make_manifest,
      luarocks_load_manifest,
      luarocks_get_rocknames_in_manifest,
      luarocks_install_from,
      luarocks_parse_installed_rocks,
      luarocks_load_rockspec,
      luarocks_list_rockspec_files
      = import 'lua-aplicado/shell/luarocks.lua'
      {
        'luarocks_exec',
        'luarocks_exec_no_sudo',
        'luarocks_exec_dir',
        'luarocks_admin_exec_dir',
        'luarocks_remove_forced',
        'luarocks_ensure_rock_not_installed_forced',
        'luarocks_make_in',
        'luarocks_exec_dir_no_sudo',
        'luarocks_pack_to',
        'luarocks_admin_make_manifest',
        'luarocks_load_manifest',
        'luarocks_get_rocknames_in_manifest',
        'luarocks_install_from',
        'luarocks_parse_installed_rocks',
        'luarocks_load_rockspec',
        'luarocks_list_rockspec_files'
      }

local remote_luarocks_remove_forced,
      remote_luarocks_ensure_rock_not_installed_forced,
      remote_luarocks_install_from,
      remote_luarocks_list_installed_rocks
      = import 'lua-aplicado/shell/remote_luarocks.lua'
      {
        'remote_luarocks_remove_forced',
        'remote_luarocks_ensure_rock_not_installed_forced',
        'remote_luarocks_install_from',
        'remote_luarocks_list_installed_rocks'
      }

local load_project_manifest
      = import 'pk-tools/project_manifest.lua'
      {
        'load_project_manifest'
      }

--------------------------------------------------------------------------------

 -- TODO: DO NOT HARDCODE PATHS!
--local PROJECT_TITLE = "pk-postcards"
--local PROJECT_PATH = os.getenv("HOME") .. "/projects/pk-postcards"
--local MANIFEST_PATH = PROJECT_PATH .. "/system/manifest"

 -- TODO: Uberhack! Must be in path. Wrap to a rock and install. (Or, better, replace with Lua code)
local GIT_TAG_TOOL_PATH = "pk-git-tag-version"

--------------------------------------------------------------------------------

local git_get_version_increment = function(path, suffix, majority)
  return trim(shell_read(
      "cd", path,
      "&&", GIT_TAG_TOOL_PATH, suffix, majority, "--dry-run"
    ))
end

local git_tag_version_increment = function(path, suffix, majority)
  return trim(shell_read(
      "cd", path,
      "&&", GIT_TAG_TOOL_PATH, suffix, majority
    ))
end

--------------------------------------------------------------------------------

-- TODO: Move these somewhere to lua-aplicado?

local write_flush = function(...)
  io.stdout:write(...)
  io.stdout:flush()
  return io.stdout
end

local writeln_flush = function(...)
  io.stdout:write(...)
  io.stdout:write("\n")
  io.stdout:flush()
  return io.stdout
end

local ask_user = function(prompt, choices, default)
  arguments(
      "string", prompt,
      "table", choices
    )
  assert(#choices > 0)

  local choices_set = tset(choices)

  writeln_flush(
      prompt, " [", table_concat(choices, ","), "]",
      default and ("=" .. default) or ""
    )

  for line in io.lines() do
    if (default and line == "") then
      return default
    end

    if choices_set[line] then
      return line
    end

    writeln_flush(
        prompt, " [", table_concat(choices, ","), "]",
        default and ("=" .. default) or ""
      )
  end

  return default -- May be nil if no default and user pressed ^D
end

local copy_file_to_dir = function(filename, dir)
  assert(shell_exec(
      "cp", filename, dir .. "/"
    ) == 0)
end

local remove_file = function(filename)
  assert(shell_exec(
      "rm", filename
    ) == 0)
end

local create_symlink_from_to = function(from_filename, to_filename)
  assert(shell_exec(
      "ln", "-s", from_filename, to_filename
    ) == 0)
end

local remote_ensure_sudo_is_passwordless = function(host)
  -- Hint: To fix do:
  -- $ sudo visudo
  -- Replace %sudo ALL=(ALL) ALL
  -- with %sudo ALL=NOPASSWD: ALL
  assert(
      shell_read_remote(host, "sudo", "echo", "-n", "yo") == "yo",
      "remote sudo is not passwordless (or some obscure error occured)"
    )
end

--------------------------------------------------------------------------------

local get_cluster_info = function(manifest, cluster_name)
  local clusters = timapofrecords(manifest.clusters, "name")
  return assert(clusters[cluster_name], "cluster not found")
end

local load_custom_versions = function(manifest, path)
  writeln_flush("----> Loading versions from `", path, "'...")

  local versions_chunk = assert(loadfile(path))
  local ok, versions = assert(do_in_environment(versions_chunk, { }))
  assert_is_table(versions)

  for k, v in pairs(versions) do
    -- TODO: Validate that all repositories are known.
    writeln_flush(k, " ", v)
  end

  return versions
end

local load_current_versions = function(manifest, cluster_info)
  local path = manifest.local_cluster_versions_path .. "/versions-current.lua"

  return load_custom_versions(manifest, path)
end

-- Assuming we're operating under atomic lock
local write_current_versions = function(manifest, cluster_info, new_versions)
  local filename = manifest.local_cluster_versions_path
    .. "/versions-" .. os.date("%Y-%m-%d-%H-%M-%S")

  local i = 1
  while does_file_exist(filename .. "-" .. i .. ".lua") do
    i = i + 1
    assert(i < 1000)
  end

  filename = filename .. "-" .. i .. ".lua"

  assert(write_file(filename, "return\n" .. tpretty(new_versions, "  ", 80)))

  return filename
end

local update_version_symlink = function(manifest, cluster_info, new_versions_filename)
  local expected_path = manifest.local_cluster_versions_path
  local versions_current_filename = expected_path .. "/versions-current.lua"

  if new_versions_filename:sub(1, 1) ~= "/" then -- TODO: ?!
    new_versions_filename = assert(manifest.project_path) .. "/" .. new_versions_filename
  end

  local path, filename = splitpath(new_versions_filename)
  assert(path == expected_path)

  remove_file(versions_current_filename)
  create_symlink_from_to(filename, versions_current_filename)
end

--------------------------------------------------------------------------------

local deploy_rocks_from_code, deploy_rocks_from_versions_filename
do
  local check_git_repo_sanity = function(manifest, name, path)
    local checker = make_checker()

    writeln_flush("----> Checking Git repository sanity...")
    git_update_index(path)

    if not (manifest.debug_mode) then
      checker:ensure(
          "must have clean working copy (hint: do commit or reset)",
          not git_is_dirty(path)
        )

      checker:ensure(
          "must have no untracked files (hint: commit or delete them)",
          not git_has_untracked_files(path)
        )

      local tracking_branch_name = checker:ensure(
          "must have tracking branch (hint: push branch to origin)",
          git_get_tracking_branch_name_of_HEAD(path)
        )

      if tracking_branch_name then
        checker:ensure(
            "all changes must be pushed",
            not git_are_branches_different(path, "HEAD", tracking_branch_name)
          )
      end
    end

    assert(checker:result("repository `" .. name .. "' "))
  end

  local calculate_update_rocks_from_versions = function(
      manifest, current_versions, new_versions, dry_run
    )
    arguments(
        "table", manifest,
        "table", current_versions,
        "table", new_versions,
        "boolean", dry_run
      )

    writeln_flush("----> Checking for changed projects...")

    local changed_rocks_set, changed_subprojects = { }, { }

    for name, version in pairs(new_versions) do
      -- TODO: Handle rock removal.

      local old_version = current_versions[name]
      if not old_version or old_version ~= version then
        writeln_flush(
            "Subproject `", name, "' version is changed from `",
            old_version or "(not installed)", "' to `", version, "'."
          )
        changed_subprojects[#changed_subprojects + 1] = name
      end
    end

    writeln_flush("----> Calculating rocks to update...")

    local subprojects = timapofrecords(manifest.subprojects, "name")

    -- TODO: Use git diff instead! There could be non-project rocks!

    for i = 1, #changed_subprojects do
      local name = changed_subprojects[i]
      local subproject = assert(subprojects[name])

      -- TODO: Hack. Do this at load time!
      if subproject.provides_rocks_repo then
        assert(not subproject.provides_rocks)
        assert(not subproject.rockspec_generator)

        if not is_table(subproject.provides_rocks_repo) then
          subproject.provides_rocks_repo = { name = subproject.provides_rocks_repo }
        end

        subproject.local_path = subproject.local_path or manifest.project_path .. "/" .. name

        for i = 1, #subproject.provides_rocks_repo do
          local rocks_repo = subproject.provides_rocks_repo[i].name

          local names = luarocks_get_rocknames_in_manifest( -- TODO: Really Bad! This will trigger full reinstall! Detect changed rocks!
              subproject.local_path .. "/" .. rocks_repo .. "/manifest"
            )
          for i = 1, #names do
            local name = names[i]
            changed_rocks_set[name] = true

            writeln_flush("Marking rock `", name, "' as changed")
          end
        end
      else
        local rocks = assert(subproject.provides_rocks)
        for i = 1, #rocks do
          local rock = rocks[i]
          changed_rocks_set[rock.name] = true

          writeln_flush("Marking rock `", rock.name, "' as changed")

          -- TODO: Rebuild rock? Note that we would have
          --       to checkout a tag to a temporary directory then.
        end
      end
    end

    return changed_rocks_set, tset(changed_subprojects)
  end

  local run_pre_deploy_actions
  do
    local handlers = { }

    handlers.add_rocks_from_pk_rocks_manifest = function(
        manifest,
        cluster_info,
        subproject,
        rocks_repo,
        current_versions,
        dry_run,
        action
      )
      local path = assert(subproject.local_path) .. "/" .. assert(rocks_repo.name)
      local manifest_path = assert(action.manifest)

      writeln_flush("----> Adding rocks from rocks manifest ", manifest_path)

      local manifest_chunk = assert(loadfile(manifest_path)) -- path should be absolute

      -- TODO: Sandbox it?
      local rocks_manifest = manifest_chunk()
      local ROCKS = assert(rocks_manifest.ROCKS)

      -- TODO: Rebuild only if rock's file dependencies is changed

      local have_changed_rocks = false

      for i = 1, #ROCKS do
        local rockspec = ROCKS[i]

        if
          rockspec["x-cluster-name"]
          and (rockspec["x-cluster-name"] ~= cluster_info.name)
        then
          -- TODO: Hack. Redesign workflow instead.
          manifest.ignore_rocks = manifest.ignore_rocks or { }
          local data = luarocks_load_rockspec(action.local_path .. "/" .. assert(rockspec[1]))
          local name = assert(data.package)
          manifest.ignore_rocks[get_filename_from_path(name)] = true

          writeln_flush(
              "----> Skipping cluster-specific rock ", name,
              " (not for our cluster)"
            )
        else
          if rockspec.generator then
            if dry_run then
              writeln_flush("-!!-> DRY RUN: Want to generate rockspecs")
            else
              writeln_flush("--> Generating rockspecs with ", tstr(rockspec.generator), "...")
              local rockspec_generator = is_table(rockspec.generator)
                and rockspec.generator
                 or { rockspec.generator }
              assert(
                  shell_exec(
                      "cd", action.local_path,
                      "&&", unpack(rockspec.generator)
                    ) == 0
                )
            end
          end

          local filename = assert(rockspec[1])
          local data = luarocks_load_rockspec(action.local_path .. "/" .. filename)
          local name = assert(data.package)

          local rockspec_files = luarocks_list_rockspec_files(action.local_path .. "/" .. assert(rockspec[1]), action.local_path)
          local rockspec_files_changed = { }

          for i = 1, #rockspec_files do
            if not current_versions[subproject.name]
              or git_is_file_changed_between_revisions(
                                action.local_path,
                                rockspec_files[i],
                                current_versions[subproject.name],
                                "HEAD"
                              )
            then
              writeln_flush("------> ", rockspec_files[i], " changed ")
              rockspec_files_changed[#rockspec_files_changed + 1] = rockspec_files[i]
            end
          end

          if #rockspec_files_changed == 0 then
            writeln_flush("------> No files changed in ", filename)
          else

            if dry_run then
              writeln_flush("-!!-> DRY RUN: Want to rebuild ", filename)
            else
              writeln_flush("----> Rebuilding `", filename, "'...")
              luarocks_ensure_rock_not_installed_forced(name)
              luarocks_make_in(filename, action.local_path)
            end

            if dry_run then
              writeln_flush("-!!-> DRY RUN: Want to pack ", filename)
            else
              writeln_flush("----> Packing `", filename, "' to `", path, "'...")
              luarocks_pack_to(name, path)
              copy_file_to_dir(action.local_path .. "/" .. filename, path)
              writeln_flush("----> Rebuilding manifest...")
              luarocks_admin_make_manifest(path)

              have_changed_rocks = true
            end

            if rockspec["x-cluster-name"] then
              if dry_run then
                writeln_flush(
                    "-!!-> DRY RUN: Want to remove cluster-specific rock after pack", name
                  )
              else
                writeln_flush("----> Removing after cluster-specific rock pack `", name, "'...")
                luarocks_ensure_rock_not_installed_forced(name)
              end
            end
          end
        end
      end

      if not have_changed_rocks then
        writeln_flush("----> No changed rocks for that rocks manifest ", manifest_path)
      else
        if dry_run then
          writeln_flush("-!!-> DRY RUN: Want to commit added rocks from rocks manifest ", manifest_path)
        else
          -- TODO: HACK! Add only generated files!
          writeln_flush("----> Committing added rocks from rocks manifest ", manifest_path, " (path: ", path, ")...")
          git_add_directory(subproject.local_path, path)
          git_commit_with_message(
              subproject.local_path,
              subproject.name .. "/" .. rocks_repo.name .. ": updated rocks"
            )
        end
      end
    end

    run_pre_deploy_actions = function(
        manifest,
        cluster_info,
        subproject,
        rocks_repo,
        pre_deploy_actions,
        current_versions,
        dry_run
      )
      arguments(
          "table", manifest,
          "table", cluster_info,
          "table", subproject,
          "table", rocks_repo,
          "table", pre_deploy_actions,
          "table", current_versions,
          "boolean", dry_run
        )

      writeln_flush("----> Running pre-deploy actions...")

      for i = 1, #pre_deploy_actions do
        local action = pre_deploy_actions[i]
        local tool_name = assert(action.tool)

        writeln_flush("----> Running pre-deploy action ", tool_name, "...")

        assert(handlers[tool_name], "unknown action")(
            manifest,
            cluster_info,
            subproject,
            rocks_repo,
            current_versions,
            dry_run,
            action
          )
      end

      writeln_flush("----> Done dunning pre-deploy actions.")
    end
  end

  local update_rocks = function(manifest, cluster_info, current_versions, dry_run)
    arguments(
        "table", manifest,
        "table", cluster_info,
        "table", current_versions,
        "boolean", dry_run
      )

    writeln_flush("----> Updating local rocks repository...")

    local changed_rocks = { }
    local need_new_versions_for_subprojects = { }

    local subprojects = manifest.subprojects

    writeln_flush("----> Checking git repo sanity for subprojects...")

    for i = 1, #subprojects do
      local subproject = subprojects[i]
      local name = subproject.name
      writeln_flush("----> Checking subproject git repo sanity for `", name, "'...")

      -- TODO: HACK! Do this at load stage.
      subproject.local_path = subproject.local_path or manifest.project_path .. "/" .. name
      check_git_repo_sanity(manifest, name, subproject.local_path)
    end

    writeln_flush("----> Collecting data from subprojects...")

    for i = 1, #subprojects do
      local subproject = subprojects[i]
      local name = subproject.name

      if subproject.no_deploy then
        writeln_flush("----> Skipping no-deploy subproject `", name, "'.")
      else
        writeln_flush("----> Collecting data from `", name, "'...")

        local path = assert(subproject.local_path)
        if current_versions[name] and not git_are_branches_different(path, "HEAD", current_versions[name]) then
          writeln_flush("No changes detected, skipping")
        else

          if not current_versions[name] then
            writeln_flush("New subproject")
          else
            writeln_flush("Changes are detected")
          end

          local current_subproject_version = current_versions[name]

          local have_changed_rocks = false

          if subproject.provides_rocks_repo then
            assert(not subproject.provides_rocks)
            assert(not subproject.rockspec_generator)

            if not is_table(subproject.provides_rocks_repo) then
              subproject.provides_rocks_repo = { name = subproject.provides_rocks_repo }
            end

            for i = 1, #subproject.provides_rocks_repo do
              local have_changed_rocks_in_repo = false
              local rocks_repo = subproject.provides_rocks_repo[i].name

              if not subproject.provides_rocks_repo[i].pre_deploy_actions then
                writeln_flush("----> No pre-deploy actions for ", name, rocks_repo)
              else
                writeln_flush("----> Running pre-deploy actions for ", name, rocks_repo)

                run_pre_deploy_actions(
                    manifest,
                    cluster_info,
                    subproject,
                    subproject.provides_rocks_repo[i],
                    subproject.provides_rocks_repo[i].pre_deploy_actions,
                    current_versions,
                    dry_run
                  )
              end

              writeln_flush("----> Searching for rocks in repo `", rocks_repo, "'...")

              local rocks = assert(luarocks_load_manifest(
                  subproject.local_path .. "/" .. rocks_repo .. "/manifest"
                ).repository)

              -- TODO: Generalize
              local rock_files, rockspec_files = { }, { }
              for rock_name, versions in pairs(rocks) do
                local have_version = false
                for version_name, infos in pairs(versions) do
                  assert(have_version == false, "duplicate rock " .. rock_name
                    .. " versions " .. version_name .. " in manifest")
                  have_version = true

                  for i = 1, #infos do
                    local info = infos[i]
                    local arch = assert(info.arch)

                    local filename = rock_name .. "-" .. version_name .. "." .. arch
                    if arch ~= "rockspec" then
                      filename = filename .. ".rock"
                    end

                    filename = rocks_repo .. "/" .. filename;

                    if arch == "rockspec" then
                      rockspec_files[rock_name] = filename
                    end

                    writeln_flush("Found `", rock_name, "' at `", filename, "'")

                    rock_files[#rock_files + 1] =
                    {
                      name = rock_name;
                      filename = filename;
                    }
                  end
                end
                assert(have_version == true, "bad rock manifest")
              end

              writeln_flush("----> Determining changed rocks...")

              local need_to_reinstall = { }
              for i = 1, #rock_files do
                local rock_file = rock_files[i]

                if
                  manifest.ignore_rocks and manifest.ignore_rocks[
                      get_filename_from_path(rock_file.name)
                    ]
                then
                  writeln_flush("--> Ignoring `", rock_file.name, "'")
                elseif
                  not current_subproject_version
                  or git_is_file_changed_between_revisions(
                      subproject.local_path,
                      rock_file.filename,
                      current_subproject_version,
                      "HEAD"
                    )
                then
                  if not changed_rocks[rock_file.name] then
                    writeln_flush("--> Changed or new `", rock_file.name, "'.")
                  end
                  changed_rocks[rock_file.name] = true
                  need_to_reinstall[rock_file.name] = true
                  have_changed_rocks = true
                  have_changed_rocks_in_repo = true
                else
                  writeln_flush("--> Not changed `", rock_file.name, "'.")
                end
              end

              if not next(need_to_reinstall) then
                writeln_flush("----> No changed rocks detected.")
              else
                writeln_flush("----> Reinstalling changed rocks...")

                for rock_name, _ in pairs(need_to_reinstall) do
                  local rockspec = assert(rockspec_files[rock_name], "rock without rockspec "..rock_name)
                  if dry_run then
                    writeln_flush("-!!-> DRY RUN: Want to reinstall", rockspec)
                  else
                    writeln_flush("----> Reinstalling `", rockspec, "'...")
                    luarocks_ensure_rock_not_installed_forced(rock_name)
                    luarocks_install_from(rock_name, subproject.local_path .. "/" .. rocks_repo)
                  end

                  if dry_run then
                    writeln_flush("-!!-> DRY RUN: Want to pack", rockspec)
                  else
                    writeln_flush("----> Packing `", rockspec, "' to `", manifest.local_rocks_repo_path, "'...")
                    luarocks_pack_to(rock_name, manifest.local_rocks_repo_path)
                    if path ~= manifest.local_rocks_repo_path then
                      copy_file_to_dir(path .. "/" .. rockspec, manifest.local_rocks_repo_path)
                    else
                      writeln_flush("Path " .. path .. " is the same as local repository path", rockspec)
                    end
                    writeln_flush("----> Rebuilding manifest...")
                    luarocks_admin_make_manifest(manifest.local_rocks_repo_path)
                  end
                end
              end

              if have_changed_rocks_in_repo then
                need_new_versions_for_subprojects[name] = true
                if dry_run then
                  writeln_flush("-!!-> DRY RUN: Want to commit changed rocks")
                else
                  -- TODO: HACK! Add only generated files!
                  writeln_flush("----> Committing changed rocks...")
                  git_add_directory(manifest.local_rocks_git_repo_path, manifest.local_rocks_repo_path)
                  git_commit_with_message(
                      manifest.local_rocks_git_repo_path,
                      "rocks/" .. cluster_info.name .. ": updated rocks for " .. name
                    )
                end
              end
            end
          else
            local rocks = assert(subproject.provides_rocks)
            if #rocks > 0 then
              if subproject.rockspec_generator then
                if dry_run then
                  writeln_flush("-!!-> DRY RUN: Want to generate rockspecs")
                else
                  writeln_flush("----> Generating rockspecs...")
                  local rockspec_generator = is_table(subproject.rockspec_generator)
                    and subproject.rockspec_generator
                     or { subproject.rockspec_generator }
                  assert(
                      shell_exec(
                          "cd", subproject.local_path,
                          "&&", unpack(rockspec_generator)
                        ) == 0
                    )
                end
              end

              writeln_flush("----> Updating rocks...")
              for i = 1, #rocks do
                local rock = rocks[i]

                local rockspec_files = luarocks_list_rockspec_files(
                    subproject.local_path .. "/" .. assert(rock.rockspec),
                    subproject.local_path  .. "/"
                  )
                local rockspec_files_changed = { }

                for i = 1, #rockspec_files do
                  if not current_versions[subproject.name]
                    or git_is_file_changed_between_revisions(
                        subproject.local_path,
                        rockspec_files[i],
                        current_versions[subproject.name],
                        "HEAD"
                      )
                  then
                    writeln_flush("------> Changed file found: ", rockspec_files[i])
                    rockspec_files_changed[#rockspec_files_changed + 1] = rockspec_files[i]
                  end
                end

                if #rockspec_files_changed == 0 then
                  writeln_flush("------> No files changed in ", rock.rockspec)
                else
                  have_changed_rocks = true
                  if
                    manifest.ignore_rocks and
                    manifest.ignore_rocks[get_filename_from_path(rock.name)]
                  then
                    writeln_flush("----> Ignoring `", rock.rockspec, "'")
                  else
                    changed_rocks[rock.name] = true

                    if rock.rockspec_generator then
                      if dry_run then
                        writeln_flush("-!!-> DRY RUN: Want to generate rock for ", rock.name)
                      else
                        writeln_flush("----> Generating rock for ", rock.name, "...")
                        local rockspec_generator = is_table(rock.rockspec_generator)
                          and rock.rockspec_generator
                           or { rock.rockspec_generator }
                        assert(
                            shell_exec(
                                "cd", subproject.local_path,
                                "&&", unpack(rockspec_generator)
                              ) == 0
                          )
                      end
                    end
                  end

                  if dry_run then
                    writeln_flush("-!!-> DRY RUN: Want to rebuild", rock.rockspec)
                  else
                    writeln_flush("----> Rebuilding `", rock.rockspec, "'...")
                    luarocks_ensure_rock_not_installed_forced(rock.name)
                    luarocks_make_in(rock.rockspec, path)
                  end

                  if dry_run then
                    writeln_flush("-!!-> DRY RUN: Want to pack", rock.rockspec)
                  else
                    writeln_flush("----> Packing `", rock.rockspec, "'...")
                    luarocks_pack_to(rock.name, manifest.local_rocks_repo_path)
                    copy_file_to_dir(path .. "/" .. rock.rockspec, manifest.local_rocks_repo_path)
                    writeln_flush("----> Rebuilding manifest...")
                    luarocks_admin_make_manifest(manifest.local_rocks_repo_path)
                  end

                  if rock.remove_after_pack then 
                  -- Needed for foreign-cluster-specific rocks, so they are not linger in our system
                    if dry_run then
                      writeln_flush("-!!-> DRY RUN: Want to remove after pack", rock.rockspec)
                    else
                      writeln_flush("----> Removing after pack `", rock.rockspec, "'...")
                      luarocks_ensure_rock_not_installed_forced(rock.name)
                    end
                  end
                end -- if #rockspec_files_changed == 0 else
              end -- for i = 1, #rocks do
            end -- if #rocks > 0 then

            if have_changed_rocks then
              need_new_versions_for_subprojects[name] = true
              if dry_run then
                writeln_flush("-!!-> DRY RUN: Want to commit changed rocks")
              else
                -- TODO: HACK! Add only generated files!
                writeln_flush("----> Committing changed rocks...")
                git_add_directory(manifest.local_rocks_git_repo_path, manifest.local_rocks_repo_path)
                git_commit_with_message(
                    manifest.local_rocks_git_repo_path,
                    "rocks/" .. cluster_info.name .. ": updated rocks for " .. name
                  )
              end
            end
          end
        end
      end
    end

    if next(changed_rocks) then
      if dry_run then
        writeln_flush("-!!-> DRY RUN: Want to rebuild manifest")
      else
        writeln_flush("----> Rebuilding manifest...")
        luarocks_admin_make_manifest(manifest.local_rocks_repo_path)

        -- TODO: HACK! Add only generated files!
        git_add_directory(manifest.local_rocks_git_repo_path, manifest.local_rocks_repo_path)
      end

      git_update_index(manifest.local_rocks_git_repo_path)
      if
        not (
            git_is_directory_dirty(manifest.local_rocks_git_repo_path, manifest.local_rocks_repo_path)
          )
      then
        writeln_flush("----> Manifest not changed")
      else
        if dry_run then
          writeln_flush("-!!-> DRY RUN: Want to commit changed manifest")
        else
          writeln_flush("----> Comitting changed manifest...")

          git_commit_with_message(
              manifest.local_rocks_git_repo_path,
              "rocks/" .. cluster_info.name .. ": updated manifest"
            )
        end
      end

      if dry_run then
        writeln_flush("-!!-> DRY RUN: Want to push manifest git repo")
      else
        writeln_flush("----> Pushing manifest git repo...")
        git_push_all(manifest.local_rocks_git_repo_path)
      end
    end

    return changed_rocks, need_new_versions_for_subprojects
  end

  local tag_new_versions = function(manifest, cluster_info, subprojects_set, dry_run)
    writeln_flush("----> Tagging new versions...")

    local new_versions = { }

    local subprojects = manifest.subprojects
    for i = 1, #subprojects do
      local subproject = subprojects[i]
      local name = subproject.name
      if not subprojects_set[name] then
        writeln_flush("----> Subproject `", name, "' not changed, skipping")
      else
        local version

        if dry_run then
          version = git_get_version_increment(subproject.local_path, cluster_info.version_tag_suffix, "build") -- TODO: Do not hardcode "build".
          writeln_flush("-!!-> DRY RUN: Want to tag subproject `", name, "' with `", version, "'")
        else
          version = git_tag_version_increment(subproject.local_path, cluster_info.version_tag_suffix, "build") -- TODO: Do not hardcode "build".
          writeln_flush("----> Subproject `", name, "' tagged `", version, "'")
        end

        new_versions[name] = version
      end
    end

    return new_versions
  end

  local fill_cluster_info_placeholders = function(manifest, cluster_info, template)
    return fill_curly_placeholders( -- TODO: Add more?
        template,
        {
          INTERNAL_CONFIG_HOST = cluster_info.internal_config_host;
          INTERNAL_CONFIG_PORT = cluster_info.internal_config_port;
          INTERNAL_CONFIG_DEPLOY_HOST = cluster_info.internal_config_deploy_host;
          INTERNAL_CONFIG_DEPLOY_PORT = cluster_info.internal_config_deploy_port;
        }
      )
  end

  local deploy_to_cluster
  do
    local action_handlers = { }

    action_handlers.local_exec = function(manifest, cluster_info, param, machine, role_args, action)
      local commands = action
      assert(#commands > 0)

      for i = 1, #commands do
        local command = commands[i]
        if not is_table(command) then
          command = { command }
        else
          command = tclone(command)
        end

        for i = 1, #command do
          command[i] = fill_cluster_info_placeholders(manifest, cluster_info, command[i])
        end

        -- Overhead to print the command to user.
        local command_str = shell_format_command(unpack(command))

        if param.dry_run then
          writeln_flush("-!!-> DRY RUN: Want to run locally: `" .. command_str .. "'")
        else
          writeln_flush("-> Running locally: `" .. command_str .. "'")

          assert(shell_exec(unpack(command)) == 0) -- TODO: Hack! Run something lower-level then, don't format command twice
        end
      end
    end

    action_handlers.remote_exec = function(manifest, cluster_info, param, machine, role_args, action)
      local commands = action
      assert(#commands > 0)

      for i = 1, #commands do
        local command = commands[i]
        if not is_table(command) then
          command = { command }
        else
          command = tclone(command)
        end

        for i = 1, #command do
          command[i] = fill_cluster_info_placeholders(manifest, cluster_info, command[i])
        end

        -- Overhead to print the command to user.
        local command_str = shell_format_command(unpack(command))

        if param.dry_run then
          writeln_flush("-!!-> DRY RUN: Want to run remotely: `" .. command_str .. "' on `" .. machine.name .. "'")
        else
          writeln_flush("-> Running remotely: `" .. command_str .. "' on `" .. machine.name .. "'")

          assert(shell_exec_remote(machine.external_url, unpack(command)) == 0)
        end
      end
    end

    action_handlers.deploy_rocks = function(manifest, cluster_info, param, machine, role_args, action)
      local rocks_must_be_installed = action
      assert(#rocks_must_be_installed > 0, "deploy_rocks: no rocks specified")

      local dry_run = param.dry_run

      -- TODO: Hack! Store state elsewhere!
      machine.deployed_rocks_set = machine.deployed_rocks_set or { }
      if not machine.installed_rocks_set then
        assert(not machine.duplicate_rocks_set)
        writeln_flush("-> Reading remote list of installed rocks from `", machine.external_url, "'")
        machine.installed_rocks_set, machine.duplicate_rocks_set = luarocks_parse_installed_rocks(
            remote_luarocks_list_installed_rocks(
                machine.external_url
              )
          )
      else
        assert(machine.duplicate_rocks_set)
        writeln_flush("-> Using cached remote list of installed rocks for `", machine.external_url, "'")
      end

      local installed_rocks_set, duplicate_rocks_set = machine.installed_rocks_set, machine.duplicate_rocks_set

      -- TODO: HACK! Don't rely on this, rely on description in role! (?!)
      --       But what about third-party rocks then?
      local installed_rocks = tkeys(installed_rocks_set)
      local duplicate_rocks = tkeys(duplicate_rocks_set)

      local changed_rocks_set = param.changed_rocks_set

      local rocks_changed = false

      if duplicate_rocks and #duplicate_rocks > 0 then
        writeln_flush("-> WARNING! Duplicate installed rocks detected")
        for i = 1, #duplicate_rocks do
          local rock_name = duplicate_rocks[i]

          if changed_rocks_set[rock_name] then
            writeln_flush("-> Delaying reinstall of remote duplicate rock " .. rock_name .. "'")
          elseif machine.deployed_rocks_set[rock_name] then
            writeln_flush("-> Skipping reinstall of remote duplicate rock " .. rock_name .. "': marked as reinstalled by someone else")
          else
            if dry_run then
              writeln_flush("-!!-> DRY RUN: Want to reinstall remote duplicate rock: `" .. rock_name .. "'")
            else
              writeln_flush("-> Removing remote duplicate rock " .. rock_name .. "'")
              remote_luarocks_remove_forced(machine.external_url, rock_name)
              writeln_flush("-> Installing remote duplicate rock " .. rock_name .. "'")
              remote_luarocks_install_from(machine.external_url, rock_name, cluster_info.rocks_repo_url)
              machine.deployed_rocks_set[rock_name] = true
              rocks_changed = true
            end
          end
        end
      end

      for i = 1, #rocks_must_be_installed do
        local rock_name = assert_is_string(rocks_must_be_installed[i])
        if not installed_rocks_set[rock_name] then
          if machine.deployed_rocks_set[rock_name] then
            writeln_flush("-> Skipping mandatory rock `" .. rock_name .. "': marked as installed by someone else")
          else
            writeln_flush("-> WARNING! Not installed mandatory rock `" .. rock_name .. "' detected")
            if dry_run then
              writeln_flush("-!!-> DRY RUN: Want to install missing rock: `" .. rock_name .. "'")
            else
              writeln_flush("-> Installing missing rock " .. rock_name .. "'")
              remote_luarocks_install_from(machine.external_url, rock_name, cluster_info.rocks_repo_url)
              machine.deployed_rocks_set[rock_name] = true
              rocks_changed = true
            end
          end
        end
      end

      local changed_rocks_list = tkeys(changed_rocks_set)
      for i = 1, #changed_rocks_list do
        local rock_name = changed_rocks_list[i]
        if not installed_rocks_set[rock_name] then
          writeln_flush("-> Skipping changed rock " .. rock_name .. "': not installed here")
        elseif machine.deployed_rocks_set[rock_name] then
          writeln_flush("-> Skipping changed rock `" .. rock_name .. "': marked as updated by someone else")
        else
          if dry_run then
            writeln_flush("-!!-> DRY RUN: Want to reinstall remote changed rock: `" .. rock_name .. "'")
          else
            writeln_flush("-> Removing remote changed rock " .. rock_name .. "'")
            remote_luarocks_remove_forced(machine.external_url, rock_name)
            writeln_flush("-> Installing remote changed rock " .. rock_name .. "'")
            remote_luarocks_install_from(machine.external_url, rock_name, cluster_info.rocks_repo_url)
            machine.deployed_rocks_set[rock_name] = true
            rocks_changed = true
          end
        end
      end

      if not rocks_changed then
        writeln_flush("-> No changes, skipping.")
      else
        writeln_flush("-> Marking `" .. machine.name .. "' to be handled at post-deploy")
        machine.need_post_deploy = true -- TODO: HACK! Store state elsewhere!
      end
    end

    action_handlers.ensure_file_access_rights = function(manifest, cluster_info, param, machine, role_args, action)
      local dry_run = param.dry_run

      if dry_run then
        writeln_flush("-!!-> DRY RUN: Want to ensure file access rights `", action.file, "' on `" .. machine.name .. "'")
      else
        -- TODO: Not flexible enough?
        writeln_flush("-> Touching `", action.file, "' on `" .. machine.name .. "'")
        assert(shell_exec_remote(
            machine.external_url, "sudo", "touch", assert(action.file)
          ) == 0)

        writeln_flush("-> Chmodding `", action.file, "' to ", action.mode, " on `" .. machine.name .. "'")
        assert(shell_exec_remote(
            machine.external_url, "sudo", "chmod", assert(action.mode), assert(action.file)
          ) == 0)

        local owner = assert(action.owner_user) .. ":" .. assert(action.owner_group)

        writeln_flush("-> Chowning `", action.file, "' to `", owner, "' on `" .. machine.name .. "'")
        assert(shell_exec_remote(
            machine.external_url, "sudo", "chown", owner, assert(action.file)
          ) == 0)
      end
    end

    deploy_to_cluster = function(
        manifest,
        cluster_info,
        param
      )

      local dry_run = param.dry_run
      local run_deploy_without_question = param.run_deploy_without_question

      if (not dry_run) and (not run_deploy_without_question) then
        if ask_user( -- TODO: Make interactivity configurable, don't want to press this on developer machine each time
            "\n\nABOUT TO DEPLOY TO `" .. cluster_info.name .. "'. ARE YOU SURE?",
            { "y", "n" },
            "n"
          ) ~= "y"
        then
          error("Aborted.")
        end
      end

      writeln_flush("----> DEPLOYING TO CLUSTER `", cluster_info.name, "'...")

      local roles = timapofrecords(manifest.roles, "name")

      local machines = cluster_info.machines

      for i = 1, #machines do
        local machine = machines[i]

        writeln_flush("---> DEPLOYING TO MACHINE `", machine.name, "' from `", cluster_info.name, "'...")

        local machine_roles = machine.roles
        for i = 1, #machine_roles do
          local role_args = machine_roles[i]
          writeln_flush("--> Deploying role `", role_args.name, "' to `", machine.name, "'...")

          local role_info = assert(roles[role_args.name], "unknown role")
          local deployment_actions = role_info.deployment_actions

          if #deployment_actions == 0 then
            writeln_flush("Role deployment actions are empty")
          else
            -- TODO: Hack? Fix error handling instead!
            if not machine.sudo_checked then -- TODO: Hack. Store state elsewhere
              -- TODO: Do this only if there is an action that requires remote sudo!
              writeln_flush("--> Checking that sudo is passwordless on `", machine.name, "'...")
              remote_ensure_sudo_is_passwordless(assert(machine.external_url))
              machine.sudo_checked = true
            end

            for i = 1, #deployment_actions do
              local action = deployment_actions[i]
              writeln_flush("--> Running role `", role_args.name, "' action ", i, ":, ", action.tool, "...")

              assert(action_handlers[action.tool], "unknown tool")(manifest, cluster_info, param, machine, role_args, action)
            end
          end

          writeln_flush("--> Done deploying role `", role_args.name, "' to `", machine.name, "'...")
        end

        writeln_flush("---> DONE DEPLOYING TO MACHINE `", machine.name, "' from `", cluster_info.name, "'...")
      end

      for i = 1, #machines do
        local machine = machines[i]

        if not machine.need_post_deploy then
          writeln_flush("---> Machine `", machine.name, "' from `", cluster_info.name, "' does not need post-deploy.")
        else
          writeln_flush("---> RUNNING POST-DEPLOY ON `", machine.name, "' from `", cluster_info.name, "'...")

          local machine_roles = machine.roles
          for i = 1, #machine_roles do
            local role_args = machine_roles[i]
            writeln_flush("--> Post-deploying role `", role_args.name, "' to `", machine.name, "'...")

            local role_info = assert(roles[role_args.name], "unknown role")
            local post_deploy_actions = role_info.post_deploy_actions

            if not post_deploy_actions or #post_deploy_actions == 0 then
              writeln_flush("Role post-deploy action is empty")
            else
              if not machine.sudo_checked then
                -- TODO: Do this only if there is an action that requires remote sudo!
                writeln_flush("--> Checking that sudo is passwordless on `", machine.name, "'...")
                remote_ensure_sudo_is_passwordless(assert(machine.external_url))
                machine.sudo_checked = true
              end

              for i = 1, #post_deploy_actions do
                local action = post_deploy_actions[i]
                writeln_flush("--> Running role `", role_args.name, "' post-deploy action ", i, ":, ", action.tool, "...")

                assert(action_handlers[action.tool], "unknown tool")(manifest, cluster_info, param, machine, role_args, action)
              end
            end

            writeln_flush("--> Done post-deploying role `", role_args.name, "' to `", machine.name, "'...")
          end
        end

        writeln_flush("---> DONE POST-DEPLOY ON `", machine.name, "' from `", cluster_info.name, "'...")
      end

      writeln_flush("----> DONE DEPLOYING TO `", cluster_info.name, "'...")
    end
  end

  local deploy_new_versions = function(
      manifest,
      cluster_info,
      changed_rocks_set,
      new_versions_filename,
      commit_new_versions,
      dry_run,
      run_deploy_without_question
    )

    deploy_to_cluster(
        manifest,
        cluster_info,
        {
          dry_run = dry_run;
          changed_rocks_set = changed_rocks_set;
          run_deploy_without_question = run_deploy_without_question;
        }
      )

    if not commit_new_versions then
      writeln_flush("-!!-> WARNING: Not updating current version as requested")
    else
      if dry_run then
        writeln_flush("-!!-> DRY RUN: Want to update version-current.lua symlink")
      else
        writeln_flush("----> Updating version-current.lua symlink.")
        update_version_symlink(manifest, cluster_info, new_versions_filename)
      end

      if dry_run then
        writeln_flush("-!!-> DRY RUN: Want to commit versions and push")
      else
        writeln_flush("----> Adding versions")
        git_add_directory(manifest.local_cluster_versions_git_repo_path, manifest.local_cluster_versions_path)

        writeln_flush("----> Committing")
        git_commit_with_message(
            manifest.local_cluster_versions_git_repo_path,
            "cluster/" .. cluster_info.name .. ": updated versions after deployment"
          )

        writeln_flush("----> Pushing")
        git_push_all(manifest.local_cluster_versions_git_repo_path)
      end
    end
  end

  deploy_rocks_from_code = function(manifest, cluster_name, dry_run)
    arguments(
        "table", manifest,
        "string", cluster_name,
        "boolean", dry_run
      )

    writeln_flush("----> Preparing to deploy to `", cluster_name, "'...")

    local cluster_info = get_cluster_info(manifest, cluster_name)

    local current_versions = load_current_versions(manifest, cluster_info)

    local changed_rocks_set, subprojects_to_be_given_new_versions_set = update_rocks(
        manifest, cluster_info, current_versions, dry_run
      )
    local run_deploy_without_question = nil

    if not next(subprojects_to_be_given_new_versions_set) then
      assert(not next(changed_rocks_set)) -- TODO: ?!
      writeln_flush("----> Nothing to deploy, you can deploy to check system integrity.")
      if ask_user(
          "\n\nDO YOU WANT TO DEPLOY TO `" .. cluster_info.name .. "'? (Not recommended!)",
          { "y", "n" },
          "n"
        ) ~= "y"
      then
        return
      else
        run_deploy_without_question = true
      end
    end

    local new_versions = twithdefaults(
        tag_new_versions(manifest, cluster_info, subprojects_to_be_given_new_versions_set, dry_run),
        current_versions
      )

    local new_versions_filename

    if dry_run then
      writeln_flush("-!!-> DRY RUN: Want to write versions file:")
      writeln_flush("return\n" .. tpretty(new_versions, '  ', 80))
    else
      -- Note that updated file is not linked as current and committed until deployment succeeds
      new_versions_filename = write_current_versions(manifest, cluster_info, new_versions)
    end

    deploy_new_versions(
        manifest,
        cluster_info,
        changed_rocks_set,
        new_versions_filename,
        true, -- Commit new versions
        dry_run,
        run_deploy_without_question
      )
  end

  deploy_rocks_from_versions_filename = function(manifest, cluster_name, new_versions_filename, commit_new_versions, dry_run)
    arguments(
        "table", manifest,
        "string", cluster_name,
        "string", new_versions_filename,
        "boolean", commit_new_versions,
        "boolean", dry_run
      )

    writeln_flush("----> Preparing to deploy to `", cluster_name, "'...")

    local cluster_info = get_cluster_info(manifest, cluster_name)

    local current_versions = load_current_versions(manifest, cluster_info)
    local new_versions = load_custom_versions(manifest, new_versions_filename)

    local changed_rocks_set, changed_subprojects_set
      = calculate_update_rocks_from_versions(
        manifest, current_versions, new_versions, dry_run
      )

    -- TODO: Look at the rocks, not at subprojects!
    if not next(changed_subprojects_set) then
      assert(not next(changed_rocks_set)) -- TODO: ?!
      writeln_flush("----> Nothing to deploy, bailing out.")
      return
    end

    deploy_new_versions(
        manifest,
        cluster_info,
        changed_rocks_set,
        new_versions_filename,
        commit_new_versions,
        dry_run
      )
  end
end

--------------------------------------------------------------------------------

local actions = { }

--------------------------------------------------------------------------------

actions.deploy_from_code = function(...)
  local cluster_name = assert(select(1, ...), "need cluster name")
  local project_path = assert(select(2, ...), "need project path")
  local manifest_path = assert(select(3, ...), "need manifest path")
  local dry_run = (select(4, ...) == "--dry-run" or select(5, ...) == "--dry-run")
  local debug = (select(4, ...) == "--debug" or select(5, ...) == "--debug")

  if not dry_run then
    if ask_user(
        "Do you want to deploy code to `" .. cluster_name .. "'?",
        { "y", "n" },
        "n"
      ) ~= "y"
    then
      error("Aborted.")
    end
  end

  local manifest = load_project_manifest(
      manifest_path,
      project_path,
      cluster_name
    )

  if debug then
    writeln_flush("-!!-> DEBUG MODE ON")
    manifest.debug_mode = true -- TODO: HACK! Store state elsewhere!
  end

  if dry_run then
    writeln_flush("-!!-> DRY RUN BEGIN <----")
  end

  deploy_rocks_from_code(
      manifest,
      cluster_name,
      dry_run
    )

  writeln_flush("----> OK")

  if dry_run then
    writeln_flush("-!!-> DRY RUN END <----")
    return
  end
end

actions.deploy_from_versions_file = function(...)
  local cluster_name = assert(select(1, ...), "need cluster name")
  local project_path = assert(select(2, ...), "need project path")
  local manifest_path = assert(select(3, ...), "need manifest path")
  local version_filename = assert(select(4, ...), "need version filename")
  local dry_run = (select(5, ...) == "--dry-run" or select(6, ...) == "--dry-run")
  local debug = (select(5, ...) == "--debug" or select(6, ...) == "--dry-run")

  if not dry_run then
    if ask_user(
        "Do you want to deploy code to `" .. cluster_name .. "'"
     .. " from version file `" .. version_filename .. "'?",
        { "y", "n" },
        "n"
      ) ~= "y"
    then
      error("Aborted.")
    end
  end

  -- TODO: Should we copy versions file to get a new timestamp?

  local manifest = load_project_manifest(
      manifest_path,
      project_path,
      cluster_name
    )

  if debug then
    writeln_flush("-!!-> DEBUG MODE ON")
    manifest.debug_mode = true -- TODO: HACK! Store state elsewhere!
  end

  if dry_run then
    writeln_flush("-!!-> DRY RUN BEGIN <----")
  end

  deploy_rocks_from_versions_filename(
      manifest,
      cluster_name,
      version_filename,
      true,
      dry_run
    )

  writeln_flush("----> OK")

  if dry_run then
    writeln_flush("-!!-> DRY RUN END <----")
    return
  end
end

actions.partial_deploy_from_versions_file = function(...)
  local cluster_name = assert(select(1, ...), "need cluster name")
  local project_path = assert(select(2, ...), "need project path")
  local manifest_path = assert(select(3, ...), "need manifest path")
  local machine_name = assert(select(4, ...), "need machine name")
  local version_filename = assert(select(5, ...), "need version filename")
  local dry_run = (select(6, ...) == "--dry-run" or select(7, ...) == "--dry-run")
  local debug = (select(6, ...) == "--debug" or select(7, ...) == "--debug")

  if not dry_run then
    if ask_user(
        "(Not recommended!) Do you want to deploy code to cluster `"
     .. cluster_name .. "' ONE machine `" .. machine_name .. "' "
     .. "from version file `" .. version_filename .. "'?"
     .. " (WARNING: Ensure you pushed changes to cluster's LR repository.)",
        { "y", "n" },
        "n"
      ) ~= "y"
    then
      error("Aborted.")
    end
  end

  -- TODO: Should we copy versions file to get a new timestamp?

  local manifest = load_project_manifest(
      manifest_path,
      project_path,
      cluster_name
    )

  if debug then
    writeln_flush("-!!-> DEBUG MODE ON")
    manifest.debug_mode = true -- TODO: HACK! Store state elsewhere!
  end

  if dry_run then
    writeln_flush("-!!-> DRY RUN BEGIN <----")
  end

  -- TODO: HACK
  do
    local clusters_by_name = timapofrecords(manifest.clusters, "name")
    local machines = assert(clusters_by_name[cluster_name], "cluster not found").machines
    local found = false
    for i = 1, #machines do
      local machine = machines[i]
      if machine.name ~= machine_name then
        writeln_flush("----> Ignoring machine `", machine.name, "'")
        machines[i] = nil
      else
        found = true
        writeln_flush("----> Deploying to machine `", machine.name, "'")
      end
    end

    assert(found == true, "machine not found")
  end

  deploy_rocks_from_versions_filename(
      manifest,
      cluster_name,
      version_filename,
      false,
      dry_run
    )

  writeln_flush("----> OK")

  if dry_run then
    writeln_flush("-!!-> DRY RUN END <----")
    return
  end
end

--------------------------------------------------------------------------------

-- TODO: AUTOMATE THIRD-PARTY MODULE UPDATES! (when our modules are not changed)
-- TODO: Check out proper branches in each repo before analysis.
-- TODO: Do with lock file
-- TODO: ALSO LOCK REMOTELY!
-- TODO: Handle rock REMOVAL!

local run = function(...)
  -- TODO: WTF?!
  local project_path = select(1, ...)
  local manifest_path = select(2, ...)
  local action_name = select(3, ...)
  local cluster_name = select(4, ...)

  assert(
      actions[action_name],
      "unknown action"
    )(
      cluster_name,
      project_path,
      manifest_path,
      select(5, ...)
    )
end

--------------------------------------------------------------------------------

return
{
  run = run;
}
