api:extend_context "example" (function()
  local try_get = function(self, api_context, field)
    method_arguments(
        self,
        "table", api_context,
        "string", transaction_id
      )
    local result = { }
    return result
  end

  local try_set = function(self, api_context)
    method_arguments(
        self,
        "table", api_context,
        "table", transaction
      )
  end

  local factory = function()

    return
    {
      try_get = try_get;
      try_set = try_set;
    }
  end

  return
  {
    factory = factory;
  }
end)
