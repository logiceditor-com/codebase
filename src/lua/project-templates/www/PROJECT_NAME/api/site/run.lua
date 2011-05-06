--------------------------------------------------------------------------------
-- run.lua: site wsapi runner
--------------------------------------------------------------------------------

pcall(require, 'luarocks.require') -- Ignoring errors

--------------------------------------------------------------------------------

require 'lua-nucleo.module'
require 'lua-nucleo.strict'

require = import 'lua-nucleo/require_and_declare.lua' { 'require_and_declare' }

exports -- Hack for WSAPI globals
{
  'main_func';
  'main_coro';
}

require "wsapi.fastcgi"
require 'wsapi.request'

--------------------------------------------------------------------------------

local reopen_log_file
do
  local common_init_logging_to_file
        = import 'pk-core/log.lua'
        {
          'common_init_logging_to_file'
        }

  -- TODO: Make configurable!
  local LOG_FILE_NAME = "/var/log/#{PROJECT_NAME}-api-wsapi.log"

  local ok
  ok, reopen_log_file = common_init_logging_to_file(LOG_FILE_NAME)
end

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

local make_loggers
      = import 'pk-core/log.lua'
      {
        'make_loggers'
      }

local make_config_manager
      = import '#{PROJECT_NAME}/internal_config_client.lua'
      {
        'make_config_manager'
      }

local make_request_manager_using_handlers
      = import 'pk-engine/webservice/request_manager.lua'
      {
        'make_request_manager_using_handlers'
      }

local collect_all_garbage
      = import 'lua-nucleo/misc.lua'
      {
        'collect_all_garbage'
      }

local xml_response,
      text_response
      = import 'pk-engine/webservice/response.lua'
      {
        'xml_response',
        'text_response'
      }

local try_get_next_task_nonblocking
      = import 'pk-engine/redis/system.lua'
      {
        'try_get_next_task_nonblocking'
      }

local HANDLERS,
      URL_HANDLER_WRAPPER
      = import 'handlers.lua'
      {
        'HANDLERS',
        'URL_HANDLER_WRAPPER'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers(
    "#{PROJECT_NAME}-api/wsapi",
    "DAW"
  )

--------------------------------------------------------------------------------

log("loading wsapi-runner (#{PROJECT_NAME}-api 1)")

--------------------------------------------------------------------------------

-- Note that it is safe to leave this exposed to the world,
-- since we've got to receive a signal for this to work.
-- NOTE: You're advised to use different urls for different services
-- TODO: Fix wsapi/luasocket, so this would not be needed. (Or, better, migrate to lua-ev)

-- TODO: Get these from internal config
local SERVICE_ID = "#{PROJECT_NAME}:api:1"
local SYSTEM_ACTION_URL = "/api/sys/#{PROJECT_NAME}-api/1/ec7719ce-0fea-11e0-af19-00219bd18c14"

local SYSTEM_ACTIONS = { }

SYSTEM_ACTIONS.reopen_log_file = function(api_context)
  log("reopening log file...")
  reopen_log_file()
  log("log file reopened")
end

SYSTEM_ACTIONS.shutdown = function(api_context)
  log("collecting garbage before shuttdown...")
  collect_all_garbage()
  log("shutting down...")
  os.exit(0) -- TODO: BAD! This would not do proper GC etc!
end

assert(not HANDLERS[SYSTEM_ACTION_URL])
HANDLERS[SYSTEM_ACTION_URL] = URL_HANDLER_WRAPPER:raw(
    function(api_context, param)
      -- TODO: Support call arguments
      local action = try_get_next_task_nonblocking(api_context, SERVICE_ID)
      if not action then
        log_error("WARNING: system action url invoked without a task in queue")
        return text_response("404 Not Found", nil, 404)
      end

      log("attempting to execute system action", action)

      local handler = SYSTEM_ACTIONS[action]
      if not handler then
        log_error("WARNING: attempted to invoke unknown system action", action)
        return text_response("404 Not Found", nil, 404)
      end

      handler(api_context)

      return xml_response([[<ok/>]])
    end,
    function() return { } end -- Input parser
  )

--------------------------------------------------------------------------------

-- Should live between calls to run()
local request_manager = make_request_manager_using_handlers(
    HANDLERS,
    make_config_manager
  )

local run = function(wsapi_env)
  --log("REQUEST", wsapi_env.PATH_INFO) -- TODO: Log full URL?
  collectgarbage("step")
  return request_manager:handle_request(wsapi_env)
end

--------------------------------------------------------------------------------

local loop = function()
  return wsapi.fastcgi.run(run)
end

--------------------------------------------------------------------------------

return
{
  loop = loop;
}
