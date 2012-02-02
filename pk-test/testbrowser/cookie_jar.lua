--------------------------------------------------------------------------------
-- pk-test/testbrowser/cookie_jar.lua: cookie jar and parser
--------------------------------------------------------------------------------

require 'getdate'

local trim,
      split_by_char,
      kv_concat,
      starts_with,
      ends_with
      = import 'lua-nucleo/string.lua'
      {
        'trim',
        'split_by_char',
        'kv_concat',
        'starts_with',
        'ends_with'
      }

local ordered_pairs
      = import 'lua-nucleo/tdeepequals.lua'
      {
        'ordered_pairs'
      }

local tremap_to_array,
      toverride_many
      = import 'lua-nucleo/table-utils.lua'
      {
        'tremap_to_array',
        'toverride_many'
      }

local arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'method_arguments'
      }

local get_domain_and_path
      = import 'pk-test/testbrowser/utils.lua'
      {
        'get_domain_and_path'
      }

local parse_cookie
      = import 'pk-test/testbrowser/parsers.lua'
      {
        'parse_cookie'
      }

--------------------------------------------------------------------------------

local make_cookie_jar
do
  -- private method
  local cookies_for_request = function(self, domain, path)
    method_arguments(
        self,
        "string", domain,
        "string", path
      )
    local jar = self.jar_
    local cookies = { }

    for d, domain_cookies in pairs(jar) do
      if ends_with(d, domain) then
        -- extra check: wildcard or exact match
        -- TODO: test for wildcards
        if starts_with(d, ".") or d == domain then
          for k, v in pairs(domain_cookies) do
            if starts_with(v.path, path) then
              cookies[k] = v.value
            end
          end
        end
      end
    end
    return cookies
  end

  local serialize_cookies = function(self, domain, path, iter_fn)
    if iter_fn == nil then
      iter_fn = pairs
    end
    method_arguments(
        self,
        "string", domain,
        "string", path,
        "function", iter_fn
      )
    local cookie_attrs = cookies_for_request(self, domain, path)
    local cookies = kv_concat(cookie_attrs, "=", "; ", iter_fn)
    return cookies
  end

  local set_headers = function(self, headers, domain, path)
    method_arguments(
        self,
        "table", headers,
        "string", domain,
        "string", path
      )
    headers['Cookie'] = self:serialize_cookies(domain, path)
  end

  local store_cookie = function(self, cookie_str, domain, path)
    method_arguments(
        self,
        "string", cookie_str,
        "string", domain,
        "string", path
      )
    local jar = self.jar_
    local cookie = parse_cookie(cookie_str)
    local status =
    {
      name = cookie.name;
      cookie = cookie;
    }
    -- TODO: validate domain and path here
    if not cookie[domain] then
      cookie.domain = domain
    end

    local cookie_for_domain = jar[domain]
    if not cookie_for_domain then
      cookie_for_domain = { }
      jar[domain] = cookie_for_domain
    end
    if cookie_for_domain[cookie.name] then
      if cookie_for_domain[cookie.name].value == cookie.value then
        status.status = "same"
      else
        status.status = "updated"
      end
    else
      status.status = "set"
    end
    cookie_for_domain[cookie.name] = cookie
    return {
        [status.name] = status
    }
  end

  make_cookie_jar = function()
    local obj =
    {
      -- public methods
      store_cookie = store_cookie;
      serialize_cookies = serialize_cookies;
      set_headers = set_headers;

      -- private
      jar_ = { };
    }
    return obj
  end
end

return
{
  make_cookie_jar = make_cookie_jar;
}
