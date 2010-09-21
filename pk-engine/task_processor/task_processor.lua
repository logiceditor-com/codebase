--------------------------------------------------------------------------------
-- task_processor.lua: entity which can run tasks
--------------------------------------------------------------------------------

local luabins = require 'luabins'

--------------------------------------------------------------------------------

local debug_traceback = debug.traceback

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

local tstr,
      tiunique,
      tvalues,
      timap,
      tserialize,
      tset,
      tclone,
      tgenerate_n,
      tkeys,
      empty_table,
      tijoin_many
      = import 'lua-nucleo/table.lua'
      {
        'tstr',
        'tiunique',
        'tvalues',
        'timap',
        'tserialize',
        'tset',
        'tclone',
        'tgenerate_n',
        'tkeys',
        'empty_table',
        'tijoin_many'
      }

local assert_is_table,
      assert_is_function,
      assert_is_string,
      assert_is_number
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table',
        'assert_is_function',
        'assert_is_string',
        'assert_is_number'
      }

local is_string
      = import 'lua-nucleo/type.lua'
      {
        'is_string'
      }

local create_channel_persistent_connections,
      make_static_multifetcher
      = import 'pk-engine/srv/channel/static_multifetcher.lua'
      {
        'create_channel_persistent_connections',
        'make_static_multifetcher'
      }

local make_loggers
      = import 'pk-core/log.lua'
      {
        'make_loggers'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers("task_processor", "TSP")

--------------------------------------------------------------------------------

local args_save = luabins.save
local args_load = luabins.load

--------------------------------------------------------------------------------

local make_task_processor
do
  -- TODO: Extract to a separate file and write tests
  local make_context
  do
    local args_save = function(self, ...)
      method_arguments(self)
      return luabins.save(...)
    end

    local args_load = function(self, data)
      method_arguments(self)
      return luabins.load(data)
    end

    local acquire_channel_connection = function(self, channel_name)
      method_arguments(
          self,
          "string", channel_name
        )
      local config_manager = self.config_manager_

      local channel_server, err = config_manager:get_channel_server(channel_name)
      if not channel_server then
        log_error("failed to get channel server for channel", channel_name, err)
        return nil, err
      end

      local server_info, err = config_manager:get_channel_node_info(channel_server)
      if not server_info then
        log_error("failed to get server info for channel server", channel_server, err)
        return nil, err
      end

      local conn, id = self.connection_manager_:acquire(server_info)

      return conn, id
    end

    local acquire_heartbeat_connection = function(self, srv_name)
      method_arguments(
          self,
          "string", srv_name
        )
      local server_info, err = self.config_manager_:get_heartbeat_node_info(srv_name)
      if not server_info then
        log_error("failed to get server info for heartbeat server ", srv_name, err)
        return nil, err
      end

      local conn, id = self.connection_manager_:acquire(server_info)

      return conn, id
    end

    local unacquire_connection = function(self, conn, id)
      method_arguments(
          self,
          "userdata", conn,
          "string", id
        )

      self.connection_manager_:unacquire(conn, id)
      conn, id = nil, nil
    end

    make_context = function(config_manager, connection_manager)
      arguments(
          "table", config_manager,
          "table", connection_manager
        )

      return
      {
        args_save = args_save;
        args_load = args_load;
        acquire_channel_connection = acquire_channel_connection;
        acquire_heartbeat_connection = acquire_heartbeat_connection;
        unacquire_connection = unacquire_connection;
        --
        config_manager_ = config_manager;
        connection_manager_ = connection_manager;
      }
    end
  end

  local task_name_from_task_filename = function(filename)
    arguments("string", filename)
    return filename:gsub("%.lua$", "")
  end
  local task_filename_from_task_name = function(name)
    arguments("string", name)
    return name .. ".lua"
  end

  local load_task
  do
    local err_handler = function(msg)
      msg = debug_traceback("task load error:\n" .. msg, 2)
      log_error(msg)
      return msg
    end

    load_task = function(filename, path, tasks)
      arguments(
        "string", filename,
        "string", path,
        "table", tasks
      )
      local full_path = path .. filename -- Note no slash inserted
      local task_name = task_name_from_task_filename(filename)
      assert(tasks[task_name] == nil, "duplicate task name")

      log("loading task", task_name, "from file", full_path)
      local chunk = assert(loadfile(full_path))
      -- TODO: Why xpcall then if we're asserting on result?
      dbg("running file", full_path, "to get", task_name)
      local res, exports = assert(xpcall(chunk, err_handler))
      tasks[task_name] = assert_is_function(
          assert_is_table(exports, "bad task exports").run,
          "missing run function"
        )
    end
  end

  -- NOTE: You're advised to call collectgarbage("step") after this function.
  local step
  do
    local err_handler = function(msg)
      msg = debug_traceback("task run error:\n" .. msg, 2)
      log_error(msg)
      return msg
    end

    local get_task = function(tasks, context, res, task_name)
      arguments(
        "table",  tasks,
        "table",  context
      )

      if not res then
        local err = task_name
        log_error("run_task: bad saved_call", err)
        return nil, err
      end

      if not task_name then
        local err = "no task name"
        log_error("run_task:", err)
        return nil, err
      end

      if not is_string(task_name) then
        local err = "task name is not a string"
        log_error("run_task:", err)
        return nil, err
      end

      local task = tasks[task_name]
      if not task then
        local err = "run_task: unknown task `"..tostring(task_name).."'"
        log_error(err)
        return nil, err
      end

      return task, task_name
    end

    local run_task = function(task, context, res, task_name, ...)
      arguments(
        "function", task,
        "table",    context,
        "boolean",  res,
        "string",   task_name
      )

      dbg("runing task", task_name)
      return task(context, ...) -- Note: task may return nil, err.
    end

    local reload_task = function(task_name, path, tasks)
      arguments(
        "string", task_name,
        "string", path,
        "table",  tasks
      )

      local task_filename = task_filename_from_task_name(task_name)
      tasks[task_name] = nil
      -- TODO: Must use pcall() / xpcall() here?
      load_task(task_filename, path, tasks)
      dbg("reloaded task", task_name)
    end

    step = function(self)
      method_arguments(self)

      dbg("step(): fetching next command")

      local channel_name, saved_call = self.fetcher_:fetch()
      if not channel_name then
        local err = data
        log_error("fetch failed:", err)
        return nil, err
      end

      spam("step(): fetched command from channel", channel_name)

      -- If fails, then it is a bug in our code. Should not happen normally.
      local tasks = assert(self.tasks_[channel_name])
      local path = assert(self.paths_[channel_name])

      local task_args = { luabins.load(saved_call) }

      local task, task_name, task_args
      do
        task_args = { luabins.load(saved_call) }
        task, task_name = get_task(tasks, self.context_, task_args[1], task_args[2])
        if task == nil then
          local err = task_name
          log_error("get_task: failed:", err)
          return nil, err
        end
      end

      local success, res, err = xpcall(
          function()
            return run_task(task, self.context_, unpack(task_args)) -- Note: task may return nil, err.
          end,
          err_handler
        )
      if not success then
        local out_err = "run_task: failed:\n"..res
        log_error(out_err)
        reload_task(task_name, path, tasks)
        return nil, out_err
      elseif res ~= true then
        if err == nil then
          err = "unknown error (missed 'return true'?)"
        end
        local out_err = "run_task: bad call:\n"..err
        log_error(out_err)
        reload_task(task_name, path, tasks)
        return nil, out_err
      end

      return true
    end
  end

  local GROUP_NAME_KEYS = { "work_group", "system_group" }

  local load_tasks = function(path, filenames)
    arguments(
        "string", path,
        "table", filenames
      )
    assert(#filenames > 0, "must have files")

    local tasks = { }

    for i = 1, #filenames do
      local name = assert_is_string(filenames[i], "bad filename")
      load_task(name, path, tasks)
    end

    return tasks
  end

  make_task_processor = function(config_manager, connection_manager, node_name)
    arguments(
        "table", config_manager,
        "table", connection_manager,
        "string", node_name
      )

    local tasks, paths = { }, { }
    do
      local node_info = assert(config_manager:get_task_node_info(node_name))
      for i = 1, #GROUP_NAME_KEYS do
        local group_name = assert(node_info[GROUP_NAME_KEYS[i]])
        local group_info = assert(config_manager:get_task_group_info(group_name))

        local channel_name = assert_is_string(group_info.channel, "bad group_info.channel")
        local path = assert_is_string(group_info.path, "bad group_info.path")
        tasks[channel_name] = load_tasks(
            path,
            assert_is_table(group_info.files, "bad group_info.files")
          )
        paths[channel_name] = path
      end
    end

    return
    {
      step = step;
      --
      context_ = make_context(config_manager, connection_manager);

      tasks_ = tasks;
      paths_ = paths;

      fetcher_ = make_static_multifetcher(
          assert(
              create_channel_persistent_connections(
                  config_manager,
                  connection_manager,
                  tkeys(tasks)
                )
            )
        );
    }
  end
end

--------------------------------------------------------------------------------

return
{
  args_save = args_save;
  args_load = args_load;
  make_task_processor = make_task_processor;
}
