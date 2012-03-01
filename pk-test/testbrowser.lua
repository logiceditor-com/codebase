--------------------------------------------------------------------------------
-- pk-test/testbrowser.lua: cookie based testbrowser
-- This file is a part of pk-test library
-- Copyright (c) Alexander Gladysh <ag@logiceditor.com>
-- Copyright (c) Dmitry Potapov <dp@logiceditor.com>
-- See file `COPYRIGHT` for the license
--------------------------------------------------------------------------------

local make_cookie_jar
      = import 'lua-aplicado/web/cookie_jar.lua'
      {
        'make_cookie_jar'
      }

local send_http_request
      = import 'pk-engine/http.lua'
      {
        'send_http_request'
      }

local arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'method_arguments'
      }

local is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_table'
      }

local ensure,
      ensure_equals,
      ensure_strequals
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_strequals'
      }

--------------------------------------------------------------------------------

local make_testbrowser
do
  --  Internal function: Let's hide all knowledge about implementation details
  local perform = function(self, method, url, request_headers, request_body)
    method_arguments(self,
        "string", method,
        "string", url,
        "table", request_headers,
        "string", request_body
      )

    -- Send relevant cookies
    request_headers['cookie'] = self.cookie_jar:format_header_for_url(url)

    local request =
      {
        method = method;
        url = url;
        ssl_options = self.ssl_options;
        request_headers = request_headers;
        request_body = request_body;
      }

    self.body, self.code, self.response_headers = send_http_request(request)

    -- Update cookies for any valid response
    if self.body and is_table(self.response_headers) then
      -- "set-cookie" in lowercase, because socket.http :lower() it
      local set_cookie_header = self.response_headers["set-cookie"]
      -- N.B. always call update to refresh state of cookies
      self.cookie_jar:update(set_cookie_header or "", url)
    end

  end

  local clear = function(self, clear_state)
    method_arguments(self)

    self.body = ""
    self.code = 0
    -- clear stored state
    if clear_state then
      self.cookie_jar:reset()
    end
  end

  -- response has particular code and body
  local ensure_response = function(self, message, code, body)
    method_arguments(self,
        "string", message,
        "number", code,
        "string", body
      )
    ensure_equals(message, code, self.code)
    ensure_strequals(message, body, self.body)
  end

  -- issue GET request
  local GET = function(self, url, request_headers)
    request_headers = request_headers or { }
    method_arguments(self,
        "string", url,
        "table", request_headers
      )
    self:clear()
    perform(self, "GET", url, request_headers, "")
    return self.code
  end

  -- issue POST request
  local POST = function(self, url, request_body, request_headers)
    request_body = request_body or ""
    request_headers = request_headers or { }
    method_arguments(self,
        "string", url,
        "string", request_body,
        "table", request_headers
      )
    self:clear()
    perform(self, "POST", url, request_headers, request_body)
  end


  make_testbrowser = function()
    local browser =
    {
      -- public fields
      code = 0;
      body = "";
      cookies_status = { };
      ssl_options = { };
      cookie_jar = make_cookie_jar();

      -- methods
      GET = GET;
      POST = POST;

      -- assertion helpers
      ensure_response = ensure_response;

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
