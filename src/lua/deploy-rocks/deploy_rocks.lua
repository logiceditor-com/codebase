local log, dbg, spam, log_error
      = import 'pk-core/log.lua' { 'make_loggers' } (
          "deploy-rocks", "DRO"
        )

--------------------------------------------------------------------------------

local pairs, pcall, assert, error, select, next, loadfile, loadstring
    = pairs, pcall, assert, error, select, next, loadfile, loadstring

local table_concat = table.concat
local os_getenv = os.getenv
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

local make_config_environment
      = import 'lua-nucleo/sandbox.lua'
      {
        'make_config_environment'
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

local writeln_flush,
      write_flush,
      ask_user,
      copy_file_to_dir,
      remove_file,
      create_symlink_from_to,
      load_table_from_file
      = import 'deploy-rocks/common_functions.lua'
      {
        'writeln_flush',
        'write_flush',
        'ask_user',
        'copy_file_to_dir',
        'remove_file',
        'create_symlink_from_to',
        'load_table_from_file'
      }

local deploy_to_cluster
      = import 'deploy-rocks/deploy_to_cluster.lua'
      {
        'deploy_to_cluster'
      }

local run_pre_deploy_actions
      = import 'deploy-rocks/run_pre_deploy_actions.lua'
      {
        'run_pre_deploy_actions'
      }

--------------------------------------------------------------------------------
 -- TODO: Uberhack! Must be in path. Wrap to a rock and install.
 --       (Or, better, replace with Lua code)
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
--------------------------------------------------------------------------------

local get_cluster_info = function(manifest, cluster_name)
  local clusters = timapofrecords(manifest.clusters, "name")
  return assert(clusters[cluster_name], "cluster not found")
end

--------------------------------------------------------------------------------

local load_current_versions = function(manifest, cluster_info)
  local path = manifest.local_cluster_versions_path .. "/versions-current.lua"
  writeln_flush("----> Loading versions from `", path, "'...")

  local versions = load_table_from_file(path)

  for k, v in pairs(versions) do
    -- TODO: Validate that all repositories are known.
    writeln_flush(k, " ", v)
  end

  return versions
end

--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------

local update_version_symlink = function(
    manifest,
    cluster_info,
    new_versions_filename
  )
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
--------------------------------------------------------------------------------

local deploy_rocks_from_code, deploy_rocks_from_versions_filename
do
  local check_git_repo_sanity = function(manifest, name, path)
    local checker = make_checker()

    writeln_flush("----> Checking Git repository sanity...")
    git_update_index(path)

    if not manifest.debug_mode then
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

--------------------------------------------------------------------------------

  local calculate_update_rocks_from_versions = function(
      manifest,
      current_versions,
      new_versions,
      dry_run
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

        subproject.local_path =
          subproject.local_path or manifest.project_path .. "/" .. name

        for i = 1, #subproject.provides_rocks_repo do
          local rocks_repo = subproject.provides_rocks_repo[i].name

          local names = luarocks_get_rocknames_in_manifest(
  -- TODO: Really Bad! This will trigger full reinstall! Detect changed rocks!
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

--------------------------------------------------------------------------------
-- TODO: move to separate file?

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
      subproject.local_path = subproject.local_path
        or manifest.project_path .. "/" .. name
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
        if
          current_versions[name] and
          not git_are_branches_different(path, "HEAD", current_versions[name])
        then
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
              subproject.provides_rocks_repo = { { name = subproject.provides_rocks_repo } }
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
                  local rockspec =
                    assert(
                        rockspec_files[rock_name],
                        "rock without rockspec "..rock_name
                      )
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
                    writeln_flush(
                        "----> Packing `", rockspec, "' to `",
                        manifest.local_rocks_repo_path, "'..."
                      )
                    luarocks_pack_to(rock_name, manifest.local_rocks_repo_path)
                    if path ~= manifest.local_rocks_repo_path then
                      copy_file_to_dir(path .. "/" .. rockspec, manifest.local_rocks_repo_path)
                    else
                      writeln_flush(
                          "Path " .. path .. " is the same as local repository path",
                          rockspec
                        )
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
                  git_add_directory(
                      manifest.local_rocks_git_repo_path,
                      manifest.local_rocks_repo_path
                    )
                  git_commit_with_message(
                      manifest.local_rocks_git_repo_path,
                      "rocks/" .. cluster_info.name .. ": updated rocks for " .. name
                    )
                end
              end
            end
          else -- if subproject.provides_rocks_repo then
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
                  -- Needed for foreign-cluster-specific rocks,
                  -- so they are not linger in our system
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
                git_add_directory(
                    manifest.local_rocks_git_repo_path,
                    manifest.local_rocks_repo_path
                  )
                git_commit_with_message(
                    manifest.local_rocks_git_repo_path,
                    "rocks/" .. cluster_info.name .. ": updated rocks for " .. name
                  )
              end
            end

          end -- if subproject.provides_rocks_repo else

        end -- if git_are_branches_different("HEAD", current_versions[name])
      end -- if subproject.no_deploy else
    end -- for i = 1, #subprojects do

    if next(changed_rocks) then
      if dry_run then
        writeln_flush("-!!-> DRY RUN: Want to rebuild manifest")
      else
        writeln_flush("----> Rebuilding manifest...")
        luarocks_admin_make_manifest(manifest.local_rocks_repo_path)

        -- TODO: HACK! Add only generated files!
        git_add_directory(
            manifest.local_rocks_git_repo_path,
            manifest.local_rocks_repo_path
          )
      end

      git_update_index(manifest.local_rocks_git_repo_path)
      if
        not git_is_directory_dirty(
            manifest.local_rocks_git_repo_path,
            manifest.local_rocks_repo_path
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

--------------------------------------------------------------------------------

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
          version =
            git_get_version_increment(
                subproject.local_path,
                cluster_info.version_tag_suffix,
                "build"  -- TODO: Do not hardcode "build".
              )
          writeln_flush(
              "-!!-> DRY RUN: Want to tag subproject `", name,
              "' with `", version, "'"
            )
        else
          version =
            git_tag_version_increment(
                subproject.local_path,
                cluster_info.version_tag_suffix,
                "build" -- TODO: Do not hardcode "build".
              )
          writeln_flush("----> Subproject `", name, "' tagged `", version, "'")
        end

        new_versions[name] = version
      end
    end

    return new_versions
  end

--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------

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
        git_add_directory(
            manifest.local_cluster_versions_git_repo_path,
            manifest.local_cluster_versions_path
          )

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

--------------------------------------------------------------------------------

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
          "\n\nDO YOU WANT TO DEPLOY TO `"
       .. cluster_info.name .. "'? (Not recommended!)",
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
        tag_new_versions(
            manifest,
            cluster_info,
            subprojects_to_be_given_new_versions_set,
            dry_run
          ),
        current_versions
      )

    local new_versions_filename

    if dry_run then
      writeln_flush("-!!-> DRY RUN: Want to write versions file:")
      writeln_flush("return\n" .. tpretty(new_versions, '  ', 80))
    else
      -- Note that updated file is not linked as current and
      -- committed until deployment succeeds
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

--------------------------------------------------------------------------------

  deploy_rocks_from_versions_filename = function(
      manifest,
      cluster_name,
      new_versions_filename,
      commit_new_versions,
      dry_run
    )
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
    local new_versions = load_table_from_file(new_versions_filename)

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

return
{
  deploy_rocks_from_versions_filename = deploy_rocks_from_versions_filename;
  deploy_rocks_from_code = deploy_rocks_from_code;
}
