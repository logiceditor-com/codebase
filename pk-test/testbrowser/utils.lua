--------------------------------------------------------------------------------
-- pk-test/testbrowser/utils.lua: misc utils
-- This file is a part of pk-test library
-- Copyright (c) Alexander Gladysh <ag@logiceditor.com>
-- Copyright (c) Dmitry Potapov <dp@logiceditor.com>
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

require 'socket.url'

local arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'method_arguments'
      }

--------------------------------------------------------------------------------

local url_parse = socket.url.parse

local get_domain_and_path = function(url)
  arguments(
      "string", url
    )
  local split = url_parse(url)
  local port = split.port ~= "" and split.port or "80"
  return (split.host .. ":" .. port), split.path
end

return
{
    get_domain_and_path = get_domain_and_path;
}
