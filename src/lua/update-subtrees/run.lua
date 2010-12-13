--------------------------------------------------------------------------------
-- run.lua: update-subtrees subtree manager
--------------------------------------------------------------------------------

local log, dbg, spam, log_error
      = import 'pk-core/log.lua' { 'make_loggers' } (
          "update-subtrees", "UST"
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

local make_checker
      = import 'lua-nucleo/checker.lua'
      {
        'make_checker'
      }

local git_load_config,
      git_config_get_remote_url,
      git_remote_add,
      git_init_subtree,
      git_pull_subtree,
      git_update_index,
      git_is_dirty,
      git_has_untracked_files,
      git_get_tracking_branch_name_of_HEAD,
      git_are_branches_different
      = import 'lua-aplicado/shell/git.lua'
      {
        'git_load_config',
        'git_config_get_remote_url',
        'git_remote_add',
        'git_init_subtree',
        'git_pull_subtree',
        'git_update_index',
        'git_is_dirty',
        'git_has_untracked_files',
        'git_get_tracking_branch_name_of_HEAD',
        'git_are_branches_different'
      }

local load_project_manifest
      = import 'pk-tools/project_manifest.lua'
      {
        'load_project_manifest'
      }

--------------------------------------------------------------------------------

local PROJECT_PATH

--------------------------------------------------------------------------------

local ACTIONS = { }

--------------------------------------------------------------------------------

ACTIONS.update = function(manifest_path, subtree_name, cluster_name)
  cluster_name = cluster_name or "UNKNOWN_CLUSTER" -- irrelevant to this tool

  arguments(
      "string", manifest_path,
      "string", cluster_name
    )
  optional_arguments(
      "string", subtree_name
    )

  local manifest = load_project_manifest(
        manifest_path,
        PROJECT_PATH,
        cluster_name
      )

  local subtrees = assert(manifest.subtrees)

  local git_configs = setmetatable(
      { },
      {
        __index = function(t, path)
          -- TODO: ?! Does this belong here?
          do
            local checker = make_checker()

            git_update_index(path)

            checker:ensure(
                "must have clean working copy (hint: do commit or reset)",
                not git_is_dirty(path)
              )

            checker:ensure(
                "must have no untracked files (hint: commit or delete them)",
                not git_has_untracked_files(path)
              )

            -- Note no tracking branch check.

            assert(checker:result())
          end

          local v = git_load_config(path)
          t[path] = v
          return v
        end;
      }
    )

  for i = 1, #subtrees do
    local subtree = subtrees[i]

    local git_dir = assert(subtree.git)
    local git_remote_name = assert(subtree.name)
    local git_remote_url = assert(subtree.url)
    local subtree_path = assert(subtree.path)

    if subtree_name and git_remote_name ~= subtree_name then
      log("skipping", git_remote_name)
    else
      log("checking", git_remote_name)

      local git_config = git_configs[git_dir]

      local actual_remote_url = git_config_get_remote_url(
          git_config,
          git_remote_name
        )

      -- TODO: Check branch as well!

      if actual_remote_url ~= git_remote_url then
        if actual_remote_url then
          error("subtree " .. git_remote_name .. " url is outdated")
        end

        if lfs.attributes(subtree_path) then
          log("initializing remote", git_remote_name, "not initializing subtree in", subtree_path)
          git_remote_add(git_dir, git_remote_name, git_remote_url, true) -- With fetch
        else
          log("initializing subtree", git_remote_name, "in", subtree_path)

          git_init_subtree(
              git_dir,
              git_remote_name,
              git_remote_url,
              assert(subtree.branch),
              subtree_path,
              "merged " .. git_remote_name .. " as a subtree to " .. subtree_path,
              false -- Not interactive
            )
        end
      else
        log("pulling subtree", git_remote_name)

        git_pull_subtree(
            git_dir,
            git_remote_name,
            assert(subtree.branch)
          )
      end
    end
  end

  log("OK")
end

--------------------------------------------------------------------------------

local run = function(...)
  -- TODO: WTF is with argument order?
  PROJECT_PATH = assert(select(1, ...), "missing project root")
  local manifest_path = assert(select(2, ...), "missing manifest path")
  local action_name = assert(select(3, ...), "missing action name")

  assert(ACTIONS[action_name], "unknown action")(manifest_path, select(4, ...))
end

--------------------------------------------------------------------------------

return
{
  run = run;
}
