--------------------------------------------------------------------------------
-- pk-test/testbrowser.lua: cookie based testbrowser
--------------------------------------------------------------------------------

-- TODO: remove declare when https://redmine.iphonestudio.ru/issues/962
--       will be fixed
declare 'curl'
require 'luacurl'

local trim,
      split_by_char,
      kv_concat
      = import 'lua-nucleo/string.lua'
      {
        'trim',
        'split_by_char',
        'kv_concat',
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

local get_domain_and_path
      = import 'pk-test/testbrowser/utils.lua'
      {
        'get_domain_and_path'
      }

local make_cookie_jar
      = import 'pk-test/testbrowser/cookie_jar.lua'
      {
        'make_cookie_jar'
      }

--------------------------------------------------------------------------------

local make_testbrowser
do
  --  Internal function: Let's hide all knowledge about curl inside
  local perform = function(self, url)
    method_arguments(self,
        "string", url
      )

    local domain, path = get_domain_and_path(url)

    -- data callback
    local data_fn = function(stream, buf)
      self.body = self.body .. buf
      return #buf
    end

    -- status/header callback
    local header_fn = function(stream, buf)
      local header, value = buf:match("([^:]+):%s+(.*)")
      if header and value then
        if header:lower() == "set-cookie" then
          local status = self.cookie_jar:store_cookie(value, domain, path)
          self.cookies_status = toverride_many(self.cookies_status, status)
        end
      end
      return #buf
    end

    local curl_setopt = function(curl_object, ...)
      local success, error_message, error_code = curl_object:setopt(...)
      if not success then
        error("Curl error " .. error_message)
      end
    end

    local headers = {}

    self.cookie_jar:set_headers(headers, domain, path)

    local c = curl.new()
    curl_setopt(c, curl.OPT_URL, url)
    curl_setopt(c, curl.OPT_HTTPHEADER,
      unpack(
        tremap_to_array(
            function(header, value)
              return header .. ": " .. value
            end,
            headers
          )
      )
    )
    curl_setopt(c, curl.OPT_WRITEFUNCTION, data_fn)
    curl_setopt(c, curl.OPT_HEADERFUNCTION, header_fn)

    local code, err = c:perform()
    if not code then
      c:close()
      error("curl error: " .. err)
    end
    self.code = c:getinfo(curl.INFO_RESPONSE_CODE)
    self.content_type = c:getinfo(curl.INFO_CONTENT_TYPE)
  end

  local clear = function(self)
      self.body = "";
      self.code = 0;
      self.cookies_status = {};
  end

  local GET = function(self, url)
    method_arguments(self,
        "string", url
      )
    self:clear()
    perform(self, url)
    return self.code
  end

  make_testbrowser = function()
    local browser =
    {
      -- public fields
      code = 0;
      body = "";
      cookies_status = {};
      cookie_jar = make_cookie_jar();

      -- methods
      GET = GET;

      -- Internal, but public
      clear = clear;
    }

    return browser
  end
end

return
{
  make_testbrowser = make_testbrowser;
}
