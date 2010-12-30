--------------------------------------------------------------------------------
-- system.lua: system Redis job queue stuff
--------------------------------------------------------------------------------
--
-- WARNING: Run code here inside call()
--
--------------------------------------------------------------------------------

local sidereal = require 'sidereal'

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

local tilistofrecordfields,
      tipermute_inplace
      = import 'lua-nucleo/table-utils.lua'
      {
        'tilistofrecordfields',
        'tipermute_inplace'
      }

local fail,
      try,
      rethrow
      = import 'pk-core/error.lua'
      {
        'fail',
        'try',
        'rethrow'
      }

local do_with_redis_lock_ttl
      = import 'pk-engine/redis/lock.lua'
      {
        'do_with_redis_lock_ttl'
      }

local rtry,
      hmset_workaround,
      hgetall_workaround,
      lpush_ilist
      = import 'pk-engine/redis/workarounds.lua'
      {
        'rtry',
        'hmset_workaround',
        'hgetall_workaround',
        'lpush_ilist'
      }

local make_loggers
      = import 'pk-core/log.lua'
      {
        'make_loggers'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers(
    "redis/system",
    "RSY"
  )

--------------------------------------------------------------------------------

local DB_NAME = "system"
local TASK_LIST_KEY_PREFIX = "task:"

local LOCK_NAME = "lock:task:all"
local LOCK_TTL = 3

--------------------------------------------------------------------------------

local system_redis = function(api_context)
  local redis = api_context:redis()
  return redis[DB_NAME](redis)
end

local task_queue_key = function(service_id)
  return TASK_LIST_KEY_PREFIX .. service_id
end

--------------------------------------------------------------------------------

local get_next_task_nonblocking = function(conn, service_id)
  arguments(
      -- "object", conn,
      "string", service_id
    )

  local list_key = task_queue_key(service_id)

  conn:ping()
  local res, err = conn:lpop(list_key)
  if not res then
    log_error(
        "get_next_task_nonblocking for service_id",
        service_id, "failed:", err
      )
    return nil, "do_next_task_nonblocking failed: " .. tostring(err)
  end

  if res == sidereal.NULL then
    return false -- Not found
  end

  return res
end

local try_get_next_task_nonblocking = function(api_context, service_id)
  arguments(
      "table", api_context,
      "string", service_id
    )

  return try(
      "INTERNAL_ERROR",
      get_next_task_nonblocking(
          system_redis(api_context),
          service_id
        )
    )
end

-- Set timeout to 0 to block forever. Timeout is in integer seconds.
-- Returns false if timeout expired
-- Returns nil, err on error
local get_next_task_blocking = function(cache, service_id, timeout)
  arguments(
      -- "object", cache,
      "string", service_id,
      "number", timeout
    )

  local list_key = task_queue_key(service_id)

  conn:ping()
  local actual_list_key, value = cache:blpop(list_key, timeout)
  if not actual_list_key then
    local err = value
    if err == "timeout" then
      --[[
      spam(
          "get_next_task_blocking for service_id", service_id,
          ": timeout", timeout, "expired"
        )
      --]]
      return false
    end

    log_error(
        "get_next_task_blocking for service_id", service_id,
        "failed:", err
      )
    return nil, "get_next_task_blocking failed: " .. tostring(err)
  end

  assert(actual_list_key == list_key, "sanity check")

  return value
end

-- Set timeout to 0 to block forever. Timeout is in integer seconds.
-- Returns false if timeout expired
-- Fails on error
local try_get_next_task_blocking = function(api_context, service_id, timeout)
  arguments(
      "table", api_context,
      "string", service_id,
      "number", timeout
    )

  return try(
      "INTERNAL_ERROR",
      get_next_task_blocking(
          system_redis(api_context),
          service_id,
          timeout
        )
    )
end

local push_task = function(conn, service_id, task_data)
  conn:ping()
  local res, err = conn:rpush(task_queue_key(service_id), task_data)
  if res == false and err then -- TODO: Hack. Remove when sidereal is fixed
    res = nil
  end

  if res == nil then
    log_error("failed to push task to service", service_id, ":", err)
    return nil, "push_task failed: " .. tostring(err)
  end

  return res
end

local try_push_task = function(api_context, service_id, task_data)
  arguments(
      "table", api_context,
      "string", service_id,
      "string", task_data
    )

  local cache = system_redis(api_context)
  try("INTERNAL_ERROR", push_task(cache, service_id, task_data))
end

--------------------------------------------------------------------------------

local try_flush_tasks = function(api_context, service_id)
  arguments(
      "table", api_context,
      "string", service_id
    )
  local cache = system_redis(api_context)
  local list_key = task_queue_key(service_id)
  conn:ping()
  rtry("INTERNAL_ERROR", cache:ltrim(list_key, 1, 0))
end

--------------------------------------------------------------------------------

return
{
  get_next_task_nonblocking = get_next_task_nonblocking;
  get_next_task_blocking = get_next_task_blocking;
  push_task = push_task;
  --
  try_get_next_task_nonblocking = try_get_next_task_nonblocking;
  try_get_next_task_blocking = try_get_next_task_blocking;
  try_push_task = try_push_task;
  --
  try_flush_tasks = try_flush_tasks;
}
