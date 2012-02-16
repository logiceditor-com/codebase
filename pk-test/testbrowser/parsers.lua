--------------------------------------------------------------------------------
-- pk-test/testbrowser/cookie_jar.lua: cookie jar and parser
-- This file is a part of pk-test library
-- Copyright (c) Alexander Gladysh <ag@logiceditor.com>
-- Copyright (c) Dmitry Potapov <dp@logiceditor.com>
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

require 'getdate'

local trim,
      split_by_char,
      kv_concat
      = import 'lua-nucleo/string.lua'
      {
        'trim',
        'split_by_char',
        'kv_concat',
      }

local make_checker
      = import 'lua-nucleo/checker.lua'
      {
        'make_checker'
      }

local arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'method_arguments'
      }

--------------------------------------------------------------------------------

-- very naive cookie parser
local parse_cookie = function(cookie_str)
  arguments(
      "string", cookie_str
    )
  local checker = make_checker()
  local parts = split_by_char(cookie_str, ";")

  local result =
    {
      path = "/";
    }

  for i=1, #parts do
    local part = trim(parts[i])
    local k, v = part:match("^([^=]+)=(.*)$")
    if k == "domain" then
      result.domain = v
    elseif k == "path" then
      result.path = v
    elseif k == "max-age" then
      result.maxage = v
    elseif k == "expires" then
      result.expires = getdate.strptime(v, "%a, %Y-%m-%d %H:%M:%S %z")
    else
      -- first k=v pair is cookie, others is options or error
      if result["name"] == nil and result["value"] == nil then
        result.name = k
        result.value = v
      else
        checker:fail("malformed cookie " .. result.name
          .. ": unknown option '" .. k .. "'")
      end
    end
  end
  local good, err = checker:result()
  return result, err
end

return
{
  parse_cookie = parse_cookie;
}
