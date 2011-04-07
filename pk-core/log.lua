--------------------------------------------------------------------------------
-- log.lua: logging facilities
--------------------------------------------------------------------------------

local socket = require 'socket'
local posix = require 'posix'

--------------------------------------------------------------------------------

local arguments,
      method_arguments,
      optional_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'method_arguments',
        'optional_arguments'
      }

local LOG_LEVEL,
      END_OF_LOG_MESSAGE,
      make_common_logging_config,
      make_logging_system,
      wrap_file_sink,
      make_loggers,
      format_logsystem_date
      = import 'lua-nucleo/log.lua'
      {
        'LOG_LEVEL',
        'END_OF_LOG_MESSAGE',
        'make_common_logging_config',
        'make_logging_system',
        'wrap_file_sink',
        'make_loggers',
        'format_logsystem_date'
      }

--------------------------------------------------------------------------------

local get_current_logsystem_date_microsecond
do
  get_current_logsystem_date_microsecond = function()
    local time = socket.gettime()
    local fractional = time % 1
    return format_logsystem_date(time)..("%.6f"):format(fractional):sub(2, -1)
  end
end

-- TODO: We MUST support USR1 signal log reload!

local COMMON_LOGGERS_INFO = -- Order is important!
{
  { suffix = " ", level = LOG_LEVEL.LOG   };
  { suffix = "*", level = LOG_LEVEL.DEBUG };
  { suffix = "#", level = LOG_LEVEL.SPAM  };
  { suffix = "!", level = LOG_LEVEL.ERROR };
}

local create_common_logging_system,
      is_common_logging_system_initialized,
      get_common_logging_system
do
  local common_logging_system = nil

  create_common_logging_system = function(...)
    -- Override intentionally disabled to ensure consistency.
    -- If needed, implement in a separate function.
    assert(
        common_logging_system == nil,
        "double create_common_logging_system call"
      )

    common_logging_system = make_logging_system(...)
  end

  is_common_logging_system_initialized = function()
    return not not common_logging_system
  end

  get_common_logging_system = function()
    return assert(common_logging_system, "common_logging_system not created")
  end
end

local common_make_loggers = function(module_name, module_prefix)
  arguments(
      "string", module_name,
      "string", module_prefix
    )

  return make_loggers(
      module_name,
      module_prefix,
      COMMON_LOGGERS_INFO,
      get_common_logging_system()
    )
end

--------------------------------------------------------------------------------

local common_init_logging_to_file
do
  local LOG_LEVEL_CONFIG =
  {
    [LOG_LEVEL.ERROR] = true;
    [LOG_LEVEL.LOG]   = true;
    [LOG_LEVEL.DEBUG] = true;
    [LOG_LEVEL.SPAM]  = true;
  }

  local LOG_MODULE_CONFIG =
  {
    -- Empty; everything is enabled by default.
  }

  local reopen_log

  common_init_logging_to_file = function(log_file_name)
    arguments(
        "string", log_file_name
      )

    if not is_common_logging_system_initialized() then
      assert(not reopen_log)

      local logging_config = make_common_logging_config(
          LOG_LEVEL_CONFIG,
          LOG_MODULE_CONFIG
        )
      local log_file = assert(io.open(log_file_name, "a"))

      reopen_log = function()
        log_file:close()
        log_file = assert(io.open(log_file_name, "a"))
      end
      local function sink(v)
        log_file:write(v)
        if v == END_OF_LOG_MESSAGE then
          log_file:flush() -- TODO: ?! Slow.
        end
        return sink
      end

      create_common_logging_system(
          "{"..("%05d"):format(posix.getpid("pid")).."} ",
          sink,
          logging_config,
          get_current_logsystem_date_microsecond
        )

      return true, reopen_log
    end

    return false, assert(reopen_log)
  end
end

--------------------------------------------------------------------------------

return
{
  get_current_logsystem_date_microsecond = get_current_logsystem_date_microsecond;
  is_common_logging_system_initialized = is_common_logging_system_initialized;
  create_common_logging_system = create_common_logging_system;
  get_common_logging_system = get_common_logging_system;
  make_loggers = common_make_loggers; -- Intentionally renamed
  --
  common_init_logging_to_file = common_init_logging_to_file;
}
