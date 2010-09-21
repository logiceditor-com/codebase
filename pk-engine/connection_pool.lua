--------------------------------------------------------------------------------
-- connection_pool.lua: pool of connection to server
--------------------------------------------------------------------------------

local socket = require 'socket'
local posix = require 'posix'

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

local make_proxying_object_pool
      = import 'pk-engine/proxying_object_pool.lua'
      {
        'make_proxying_object_pool'
      }

local make_loggers
      = import 'pk-core/log.lua'
      {
        'make_loggers'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers("connection_pool", "CPO")

--------------------------------------------------------------------------------

local make_connection_pool
do
  local acquire = function(self)
    method_arguments(
        self
      )

    local pool = self.pool_

    local conn = pool:acquire()
    if not conn then
      pool:own(self.persistent_connector_:connect())
      conn = assert(pool:acquire())
    end

    return conn
  end

  local unacquire = function(self, conn)
    method_arguments(
        self,
        "userdata", conn
      )

    self.pool_:unacquire(conn)
  end

  make_connection_pool = function(persistent_connector)
    arguments(
        "table", persistent_connector
      )

    return
    {
      acquire = acquire;
      unacquire = unacquire;
      --
      pool_ = make_proxying_object_pool();
      persistent_connector_ = persistent_connector;
    }
  end
end

--------------------------------------------------------------------------------

return
{
  make_connection_pool = make_connection_pool;
}
