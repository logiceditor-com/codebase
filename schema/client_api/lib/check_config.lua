
api:export "check_config"
{
  exports =
  {
    "load_config_data_schema";
    "load_config";
  };

  handler = function()
    local get_config_data_walkers
      = import 'pk-core/config_dsl.lua'
      {
        'get_data_walkers'
      }
    --------------------------------------------------------------------------------

    local load_config_data_schema
    do
      local extra_env =
      {
        import = import; -- Trusted sandbox
      }

      load_config_data_schema = function(schema_chunk)
        arguments("function", schema_chunk)
        return load_data_schema(schema_chunk, extra_env, { "cfg" })
      end
    end

    --------------------------------------------------------------------------------

    local load_config_data
    do
      load_config_data = function(schema, data, env)
        if is_function(schema) then
          schema = load_config_data_schema(schema)
        end

        arguments(
            "table", schema,
            "table", data
          )

        local checker = get_config_data_walkers()
          :walk_data_with_schema(
              schema,
              data,
              data -- use data as environment for string_to_node
            )
          :get_checker()

        if not checker:good() then
          return checker:result()
        end

        return data
      end
    end

    --------------------------------------------------------------------------------

    local parse_config_arguments = function(canonicalization_map, ...)
      arguments("table", canonicalization_map)

      local n = select("#", ...)

      local args = { }

      local i = 1
      while i <= n do
        local arg = select(i, ...)
        if arg:match("^%-%-[^%-=].-=.*$") then
          -- TODO: Optimize. Do not do double matching
          local name, value = arg:match("^(%-%-[^%-=].-)=(.*)$")
          assert(name)
          assert(value)
          args[canonicalization_map[name] or name] = value
        elseif arg:match("^%-[^%-].*$") then
          local name = arg

          i = i + 1
          local value = select(i, ...)

          args[canonicalization_map[name] or name] = value
        elseif arg:match("^%-%-[^%-].*$") then
          -- TODO: Optimize. Do not do double matching
          local name, value = arg, true
          assert(name)
          assert(value)
          args[canonicalization_map[name] or name] = value
        else
          local name = canonicalization_map[arg] or arg
          args[#args + 1] = name
          args[name] = true
        end
        i = i + 1
      end

      return args
    end

    --------------------------------------------------------------------------------

    local raw_config_table_key = unique_object()

    local raw_config_table_callback = function(t)
      return t
    end

    local load_config
    do
      local callbacks = { [raw_config_table_key] = raw_config_table_callback }

      load_config = function(
          schema,
          CONFIG -- config table here
        )
        arguments(
            "table", schema,
            "table", CONFIG
          )

        if CONFIG.import == import then
          CONFIG.import = nil -- TODO: Hack. Use metatables instead
        end

        if CONFIG.rawget == rawget then
          CONFIG.rawget = nil -- TODO: Hack. Use metatables instead
        end

        return load_config_data(schema, make_config_environment(CONFIG))
      end
    end

  end
}
