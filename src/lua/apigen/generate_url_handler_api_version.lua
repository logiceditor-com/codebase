--------------------------------------------------------------------------------
-- generate_url_handlers_api_version.lua: api url client_api_version generator
--------------------------------------------------------------------------------

local arguments,
      optional_arguments,
      method_arguments,
      eat_true
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments',
        'eat_true'
      }

local make_concatter
      = import 'lua-nucleo/string.lua'
      {
        'make_concatter'
      }

local walk_tagged_tree
      = import 'pk-core/tagged-tree.lua'
      {
        'walk_tagged_tree'
      }

local make_loggers
      = import 'pk-core/log.lua'
      {
        'make_loggers'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers(
    "generate_url_handler_api_version", "GUA"
  )

--------------------------------------------------------------------------------

local generate_url_handler_api_version
do
  generate_url_handler_api_version = function(
      schema
    )
    arguments(
        "table", schema
      )

    return [[
--------------------------------------------------------------------------------
-- client_api_version.lua: generated client api version file
--------------------------------------------------------------------------------
-- WARNING! Do not change manually.
-- Generated by apigen.lua
--------------------------------------------------------------------------------

local CLIENT_API_VERSION = ]] .. (("%q"):format(schema.version)) .. [[


--------------------------------------------------------------------------------

return
{
  CLIENT_API_VERSION = CLIENT_API_VERSION;
}
]]
  end
end

--------------------------------------------------------------------------------

return
{
  generate_url_handler_api_version = generate_url_handler_api_version;
}
