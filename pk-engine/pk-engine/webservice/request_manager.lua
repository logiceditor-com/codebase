--------------------------------------------------------------------------------
-- request_manager.lua: wsapi request manager
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

local is_number,
      is_string
      = import 'lua-nucleo/type.lua'
      {
        'is_number',
        'is_string'
      }

local assert_is_number,
      assert_is_table,
      assert_is_function
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_number',
        'assert_is_table',
        'assert_is_function'
      }

local make_net_connection_manager
      = import 'pk-engine/net/net_connection_manager.lua'
      {
        'make_net_connection_manager'
      }

local make_db_connection_manager
      = import 'pk-engine/db/db_connection_manager.lua'
      {
        'make_db_connection_manager'
      }

local make_db_manager
      = import 'pk-engine/db/db_manager.lua'
      {
        'make_db_manager'
      }

local make_redis_manager,
      make_redis_connection_manager
      = import 'pk-engine/redis/redis_manager.lua'
      {
        'make_redis_manager',
        'make_redis_connection_manager'
      }

local make_default_config_manager
      = import 'pk-engine/srv/internal_config/client.lua'
      {
        'make_config_manager'
      }

local make_loggers
      = import 'pk-core/log.lua'
      {
        'make_loggers'
      }

local wsapi_send,
      append_no_cache_headers
      = import 'pk-engine/webservice/wsapi.lua'
      {
        'wsapi_send',
        'append_no_cache_headers'
      }

local text_response
      = import 'pk-engine/webservice/response.lua'
      {
        'text_response'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers("request_manager", "RMN")

--------------------------------------------------------------------------------

local handler_404 = function(context)
  log("404", context.wsapi_env.PATH_INFO)
  return text_response("404 Not Found", nil, 404)
end

--------------------------------------------------------------------------------

local make_filesystem_request_handler
do
  local handle_request = function(self, context)
    method_arguments(
        self,
        "table", context
      )

    local handler = self.handlers_[context.wsapi_env.PATH_INFO] or handler_404
    return handler(context)
  end

  make_filesystem_request_handler = function(url_to_handler, path_pattern)
    path_pattern = path_pattern or "handlers%s.lua"

    arguments(
        "table", url_to_handler,
        "string", path_pattern
      )

    local handlers = { }

    for path_info, handler_file in pairs(url_to_handler) do
      if is_number(path_info) then
        path_info = handler_file
      end

      handlers[path_info] = import(path_pattern:format(handler_file))
      {
        'handle'
      }
    end

    return
    {
      handle_request = handle_request;
      --
      handlers_ = handlers;
    }
  end
end

--------------------------------------------------------------------------------

local make_request_manager
do
  -- Private function.
  local get_context -- NOTE: When changing this, remember to change api_context_stub.lua as well!
  do
    local create_common_context = function(wsapi_env, config_manager_maker)
      arguments(
          "table", wsapi_env,
          "function", config_manager_maker
        )

      local config_host = wsapi_env.PK_CONFIG_HOST
      local config_port = tonumber(wsapi_env.PK_CONFIG_PORT)

      if not config_host or not config_port then
        log_error(
              "bad wsapi_env",
              "PK_CONFIG_HOST:", wsapi_env.PK_CONFIG_HOST,
              "PK_CONFIG_PORT:", wsapi_env.PK_CONFIG_PORT,
              "all:", wsapi_env
            )
        error("missing config host and/or port")
      end

      local config_manager = config_manager_maker(config_host, config_port)

      return
      {
        config_manager = config_manager;
        net_connection_manager = make_net_connection_manager();
        db_manager = make_db_manager(config_manager, make_db_connection_manager());
        redis_manager = make_redis_manager(config_manager, make_redis_connection_manager());
      }
    end

    -- Returned context is guaranteed to be single-use data.
    -- Feel free to change it (just don't touch the metatable and wsapi_env).
    -- TODO: Remove restriction on wsapi_env
    get_context = function(self, wsapi_env)
      method_arguments(
          self,
          "table", wsapi_env
        )

      if not self.common_context_mt_ then
        self.common_context_mt_ =
        {
          __index = create_common_context(wsapi_env, self.config_manager_maker_);
          __metatable = true;
        }
      end

      local context = setmetatable(
          {
            wsapi_env = wsapi_env;
          },
          self.common_context_mt_
        )

      -- Hack. Remove this limitation.
      assert(context.wsapi_env == wsapi_env)

      return context
    end
  end

  local handle_request
  do
    local error_handler = function(msg)
      log_error(debug.traceback(msg, 2))
      return msg
    end

    handle_request = function(self, wsapi_env)
      method_arguments(
          self,
          "table", wsapi_env
        )

      local context = get_context(self, wsapi_env)
      local ok, status, body, headers = xpcall(
          function() return self.request_handler_:handle_request(context) end,
          error_handler
        )

      if not ok then
        -- NOTE: Error is already logged in error_handler.

        -- Using text_response()
        -- only because it is used everywhere else
        status, body, headers = text_response(
            "500 Internal Error",
            nil,
            500
          )
      end

      if is_string(body) then
        local body_string = body
        body = coroutine.wrap(function() wsapi_send(body_string) end)
      end

      -- WARNING: If body is a function, provided by handler,
      --          it MUST NOT crash, or user will see error message!

      if is_string(headers) then
        headers = append_no_cache_headers
        {
          ["Content-type"] = headers;
        }
      end

      -- WARNING! Do not uncomment! Too much spamming on heavy load!
      -- log(status, context.wsapi_env.PATH_INFO)

      return
        assert_is_number(status),
        assert_is_table(headers),
        assert_is_function(body)
    end
  end

  make_request_manager = function(request_handler, config_manager_maker)
    arguments(
        "table", request_handler,
        "function", config_manager_maker
      )
    optional_arguments(
        "function", config_manager_maker
      )

    config_manager_maker = config_manager_maker or make_default_config_manager

    return
    {
      handle_request = handle_request;
      --
      request_handler_ = request_handler;
      common_context_mt_ = nil;
      config_manager_maker_ = config_manager_maker;
    }
  end
end

local make_request_manager_using_handlers
do
  local handle_request = function(self, context)
    method_arguments(
        self,
        "table", context
      )

    local handler = (self.handlers_[context.wsapi_env.PATH_INFO] or handler_404)
    return handler(context)
  end

  local make_request_handler = function(handlers)
    arguments(
        "table", handlers
      )

    return
    {
      handle_request = handle_request;
      --
      handlers_ = handlers;
    }
  end

  make_request_manager_using_handlers = function(handlers, config_manager_maker)
    arguments(
        "table", handlers
      )
    optional_arguments(
        "function", config_manager_maker
      )

    return make_request_manager(make_request_handler(handlers), config_manager_maker)
  end
end

--------------------------------------------------------------------------------

return
{
  make_request_manager_using_handlers = make_request_manager_using_handlers;

  -- TODO: Only for backward compatibility with hospital
  handler_404 = handler_404;
  make_filesystem_request_handler = make_filesystem_request_handler;
  make_request_manager = make_request_manager;
}
