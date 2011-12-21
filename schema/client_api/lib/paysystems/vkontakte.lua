api:export "lib/paysystems/vkontakte"
{
  exports =
  {
    -- methods
    "vk_withdraw_votes";
  };

  handler = function()
    local vk_withdraw_votes = function(user_agent, user_id, money_amount, application)
      arguments(
          "string", user_agent,
          "string", user_id,
          "string", money_amount,
          "table", application
        )
      local md5_sumhexa = md5.sumhexa
      local math_random = math.random

      local vk_app_id = application.config.vk_app_id
      local vk_app_key = application.config.vk_app_key
      local timestamp = os.time()
      local rand = math_random()

      -- TODO: check params, enable test_mode if needed
      local sig = md5_sumhexa(
          "api_id=" .. vk_app_id
       .. "format=json"
       .. "method=secure.withdrawVotes"
       .. "random=" .. rand
      -- .. "test_mode=true"
       .. "timestamp=" .. timestamp
       .. "uid=" .. user_id
     --  .. "v=2.0"
       .. "votes=" .. money_amount
       .. vk_app_key);

      local request_body =
        "api_id=" .. vk_app_id
     .. "&format=json"
     .. "&method=secure.withdrawVotes"
     .. "&random=" .. rand
     .. "&timestamp=" .. timestamp
     --.. "&test_mode=true"
     .. "&uid=" .. user_id
     --.. "&v=2.0"
     .. "&votes=" .. money_amount
     .. "&sig=" .. sig;

      local response_body, err = common_send_http_request(
          {
            url = VK_API_URL;
            method = "POST";
            request_body = request_body;
            headers =
            {
              ["User-Agent"] = user_agent;
            };
          }
        )

      if not response_body then
        fail("EXTERNAL_ERROR", "pkb_send_http_request: " .. err)
      end

      local json_util = require 'json.util'
      local json_decode = require 'json.decode'
      local json_decode_util = require 'json.decode.util'
      local decode_options = json_util.merge(
          {
            object =
            {
              setObjectKey = json_decode_util.setObjectKeyForceNumber;
            };
          },
          json_decode.simple
        )

      local ok, response = pcall(json_decode, response_body,  decode_options)
      if not ok then
        log_error("[vk_withdraw_votes] failed to parse:", response_body)
        local err = "parse error: " .. response
        return nil, err
      elseif response == nil or response.error ~= nil or response.response == nil then
        local err = response and response.error or "UNKNOWN"
        return nil, "VK returned error: " .. tostring(err)
      end

      log("[vk_withdraw_votes] OK, ", money_amount, user_id)

      return response.response.transferred
    end
  end
}
