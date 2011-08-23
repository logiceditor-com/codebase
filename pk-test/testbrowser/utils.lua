--------------------------------------------------------------------------------
-- pk-test/testbrowser/utils.lua: misc utils
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

-- should be in nucleo
local startswith = function(str, prefix)
  local plen = #prefix
  return (#str >= plen) and (str:sub(1, plen) == prefix)
end

-- should be in nucleo
local endswith = function(str, suffix)
  local slen = #suffix
  local len = #str
  return (len >= slen) and (str:sub(-slen, -1) == suffix)
end

return
{
    get_domain_and_path = get_domain_and_path;
    startswith = startswith;
    endswith = endswith;
}
