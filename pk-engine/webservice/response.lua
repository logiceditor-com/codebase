--------------------------------------------------------------------------------
-- response.lua: webservice response utilities
--------------------------------------------------------------------------------

local luabins = require 'luabins'

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

local is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_table'
      }

--------------------------------------------------------------------------------

local common_html_error = function(error_id)
  arguments(
      "string", error_id
    )

  return '<H1>Error!</H1>' .. error_id -- TODO: Cache results?
end

local common_text_error = function(error_id)
  arguments(
      "string", error_id
    )

  return 'Error!\n\n' .. error_id -- TODO: Cache results?
end

-- Note that error_id is intentionally not escaped.
-- It must be valid XML parameter value
local common_xml_error = function(error_id)
  arguments(
      "string", error_id
    )

  return '<error id="' .. error_id .. '"/>' -- TODO: Cache results?
end

-- Note that error_id is intentionally not escaped.
-- It must be valid json string
local common_json_error = function(error_id)
  arguments(
      "string", error_id
    )

  return '{ "error" : { "id" : "' .. error_id .. '" } }' -- TODO: Cache results?
end

local common_luabins_error = function(error_id)
  arguments(
      "string", error_id
    )

  -- TODO: Cache results?
  return assert(luabins.save(nil, error_id))
end

--------------------------------------------------------------------------------

local html_response = function(body, headers, status)
  if is_table(headers) then
    headers["Content-type"] = headers["Content-type"] or 'text/html'
  end
  return status or 200, body, headers or 'text/html'
end

local xml_response = function(body, headers, status)
  if is_table(headers) then
    headers["Content-type"] = headers["Content-type"] or 'text/xml'
  end
  return status or 200, body, headers or 'text/xml'
end

local text_response = function(body, headers, status)
  if is_table(headers) then
    headers["Content-type"] = headers["Content-type"] or 'text/plain'
  end
  return status or 200, body, headers or 'text/plain'
end

local json_response = function(body, headers, status)
  if is_table(headers) then
    headers["Content-type"] = headers["Content-type"] or 'application/json'
  end
  return status or 200, body, headers or 'application/json'
end

local luabins_response = function(body, headers, status)
  if is_table(headers) then
    headers["Content-type"] = headers["Content-type"]
      or 'application/octet-stream'
  end
  return status or 200, body, headers or 'application/octet-stream'
end

local gif_response = function(body, headers, status)
  if is_table(headers) then
    headers["Content-type"] = headers["Content-type"] or 'image/gif'
  end
  return status or 200, body, headers or 'image/gif'
end

--------------------------------------------------------------------------------

local common_http_redirect = function(target_url)
  return html_response( -- Note that target_url is not escaped.
      '<a href="' .. target_url .. '">Redirecting...</a>',
      {
        ["Location"] = target_url;
      },
      302 -- TODO: make configurable, 301 is also viable sometimes.
    )
end

--------------------------------------------------------------------------------

return
{
  common_html_error = common_html_error;
  common_xml_error = common_xml_error;
  common_text_error = common_text_error;
  common_json_error = common_json_error;
  common_luabins_error = common_luabins_error;
  --
  html_response = html_response;
  xml_response = xml_response;
  text_response = text_response;
  json_response = json_response;
  luabins_response = luabins_response;
  gif_response = gif_response;
  --
  common_http_redirect = common_http_redirect;
}
