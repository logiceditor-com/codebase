--------------------------------------------------------------------------------
-- pk-test/testbrowser.lua: cookie based testbrowser
--------------------------------------------------------------------------------

local send_http_request
      = import 'pk-engine/http.lua'
      {
        'send_http_request'
      }

local is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_table'
      }

local tclone,
      toverride_many
      = import 'lua-nucleo/table-utils.lua'
      {
        'tclone',
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
  --  Internal function: Let's hide all knowledge about implementation details
  local perform = function(self, method, url, request_headers, request_body)
    method_arguments(self,
        "string", method,
        "string", url,
        "table", request_headers,
        "string", request_body
      )

    local domain, path = get_domain_and_path(url)

    self.cookie_jar:set_headers(request_headers, domain, path)

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
      if set_cookie_header then
        local status = self.cookie_jar:store_cookie(
            set_cookie_header,
            domain,
            path
          )
        self.cookies_status = toverride_many(self.cookies_status, status)
      end
    end

  end

  local clear = function(self)
      self.body = "";
      self.code = 0;
      self.cookies_status = {};
  end

  local GET = function(self, url, request_headers)
    request_headers = request_headers or {}
    method_arguments(self,
        "string", url,
        "table", request_headers
      )
    self:clear()
    perform(self, "GET", url, request_headers, "")
    return self.code
  end

  make_testbrowser = function()
    local browser =
    {
      -- public fields
      code = 0;
      body = "";
      cookies_status = {};
      ssl_options = {};
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
