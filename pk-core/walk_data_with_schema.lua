--------------------------------------------------------------------------------
-- walk_data_with_schema.lua: data walking based on tagged-tree schemas
--------------------------------------------------------------------------------
-- Sandbox warning: alias all globals!
--------------------------------------------------------------------------------

local table_concat, table_insert, table_remove
    = table.concat, table.insert, table.remove

local debug_traceback = debug.traceback

local assert, error, pairs, rawset, rawget, select
    = assert, error, pairs, rawset, rawget, select

local setfenv, setmetatable, tostring, xpcall
    = setfenv, setmetatable, tostring, xpcall

--------------------------------------------------------------------------------

local arguments,
      optional_arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments'
      }

local is_table,
      is_function
      = import 'lua-nucleo/type.lua'
      {
        'is_table',
        'is_function'
      }

local assert_is_nil,
      assert_is_table,
      assert_is_function
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_nil',
        'assert_is_table',
        'assert_is_function'
      }

local do_nothing
      = import 'lua-nucleo/functional.lua'
      {
        'do_nothing'
      }

local unique_object
      = import 'lua-nucleo/misc.lua'
      {
        'unique_object'
      }

local make_checker
      = import 'lua-nucleo/checker.lua'
      {
        'make_checker'
      }

local tkeys,
      tclone,
      tset,
      torderedset,
      torderedset_insert,
      torderedset_remove,
      twithdefaults,
      tivalues
      = import 'lua-nucleo/table-utils.lua'
      {
        'tkeys',
        'tclone',
        'tset',
        'torderedset',
        'torderedset_insert',
        'torderedset_remove',
        'twithdefaults',
        'tivalues'
      }

local make_loggers
      = import 'pk-core/log.lua'
      {
        'make_loggers'
      }

local make_dsl_loader
      = import 'pk-core/dsl_loader.lua'
      {
        'make_dsl_loader'
      }

local walk_tagged_tree
      = import 'pk-core/tagged-tree.lua'
      {
        'walk_tagged_tree'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers("pk-core/validate_table", "EVT")

--------------------------------------------------------------------------------

-- TODO: Lazy! Do not create so many closures!
local load_data_schema -- TODO: Generalize more. Apigen uses similar code.
do
  load_data_schema = function(chunk, extra_env, allowed_namespaces)
    extra_env = extra_env or { }
    arguments(
        "function", chunk,
        "table", extra_env
      )
    optional_arguments(
        "table", allowed_namespaces
      )
    if allowed_namespaces then
      allowed_namespaces = tset(allowed_namespaces)
    end

    local positions = torderedset({ })
    local unhandled_positions = { }
    local soup = { }

    local make_common_loader = function(namespace)
      arguments("string", namespace)

      local name_filter = function(tag, name, ...)
        assert(select("#", ...) == 0, "extra arguments are not supported")

        local data

        if is_table(name) then -- data-only-call
          -- Allowing data.name to be missing.
          data = name
        elseif is_function(name) then -- handler-only-call
          -- Allowing data.name to be missing.
          data =
          {
            handler = name;
          }
        else -- normal named call
          data =
          {
            name = name;
          }
        end

        data.tag = tag
        data.namespace = namespace;
        data.id = namespace .. ":" .. tag

        torderedset_insert(positions, data)
        unhandled_positions[data] = positions[data]

        return data
      end

      local data_filter = function(name_data, value_data)
        assert_is_table(name_data)

        -- A special case for handler-only named tags
        if is_function(value_data) then
          value_data =
          {
            handler = value_data;
          }
        end

        -- Letting user to override any default values (including name and tag)
        local data = twithdefaults(value_data, name_data)

        local position = assert(positions[name_data])
        assert(soup[position] == nil)
        soup[position] = data

        -- Can't remove from set, need id to be taken
        unhandled_positions[name_data] = nil

        return data
      end

      return make_dsl_loader(name_filter, data_filter)
    end

    local loaders = { }

    local environment = setmetatable(
        { },
        {
          __index = function(t, namespace)
            -- Can't put it as setmetatable first argument -- 
            -- we heavily change that table afterwards.
            local v = extra_env[namespace]
            if v ~= nil then
              return v
            end

            -- TODO: optimizable. Employ metatables.
            if allowed_namespaces and not allowed_namespaces[namespace] then
              error(
                  "attempted to read from global `"
               .. tostring(namespace) .. "'",
                  2
                )
            end

            local loader = make_common_loader(namespace)
            loaders[namespace] = loader

            local v = loader:get_interface()
            rawset(t, namespace, v)
            return v
          end;

          __newindex = function(t, k, v)
            error("attempted to write to global `" .. tostring(k) .. "'", 2)
          end;
        }
      )

    -- TODO: Restore chunk environment?
    setfenv(
        chunk,
        environment
      )

    assert(
        xpcall(
            chunk,
            function(err)
              log_error("failed to load schema:\n" .. debug_traceback(err))
              return err
            end
          )
      )

    -- For no-name top-level tags
    for data, position in pairs(unhandled_positions) do
      assert(soup[position] == nil)
      soup[position] = data
    end

    assert(#soup > 0, "no data in schema")

    for _, loader in pairs(loaders) do
      soup = loader:finalize_data(soup)
    end

    -- TODO: OVERHEAD! Try to get the list of top-level nodes from dsl_loader.
    soup = torderedset(soup)

    local function unsoup(soup, item)
      for k, v in pairs(item) do
        if is_table(k) then
          torderedset_remove(soup, k)
          unsoup(soup, k)
        end
        if is_table(v) then
          torderedset_remove(soup, v)
          unsoup(soup, v)
        end
      end

      return soup
    end

    local n_soup = #soup
    for i = 1, n_soup do
      if soup[i] ~= nil then -- may be already unsouped
        unsoup(soup, soup[i])
      end
    end

    local schema = tivalues(soup)

    return schema
  end
end

--------------------------------------------------------------------------------

-- TODO: Generalize?
local make_prefix_checker
do
  local fail = function(self, msg)
    method_arguments(
        self,
        "string", msg
      )

    local errors = self.errors_
    errors[#errors + 1] = "bad `"
      .. table_concat(self.prefix_getter_(), ".") .. "': "
      .. msg
  end

  -- Imitates checker interface
  make_prefix_checker = function(prefix_getter)
    arguments("function", prefix_getter)

    local checker = make_checker()

    return setmetatable(
        {
          fail = fail;
          --
          prefix_getter_ = prefix_getter;
        },
        {
          __index = checker;
        }
      )
  end
end

--------------------------------------------------------------------------------

-- TODO: Lazy! Do not create so many closures!
-- TODO: Generalize copy-paste
local load_data_walkers = function(chunk, extra_env)
  extra_env = extra_env or { }
  arguments(
      "function", chunk,
      "table", extra_env
    )

  local schema = load_data_schema(chunk, extra_env, { "types" })
  assert(#schema > 0)

  local types =
  {
    down = nil; -- See below
    up = nil;
    --
    set_data = function(self, data)
      method_arguments(
          self,
          "table", data
        )

      assert(self.data_ == nil)
      assert(#self.current_path_ == 0)
      self.data_ = data
    end;

    reset = function(self)
      method_arguments(self)
      self.data_ = nil
      self.current_path_ = { }
      self.current_leaf_name_ = nil
      self.checker_ = make_prefix_checker(self.get_current_path_closure_);
      self.context_ = self.factory_(
          self.checker_,
          self.get_current_path_closure_
        )
    end;

    get_checker = function(self)
      method_arguments(self)
      return self.checker_
    end;

    get_context = function(self)
      method_arguments(self)
      return self.context_
    end;

    get_current_path = function(self)
      method_arguments(self)
      local buf = { }
      for i = 1, #self.current_path_ do
        local name = self.current_path_[i].name
        if name ~= "" then -- To allow nameless root
          buf[#buf + 1] = self.current_path_[i].name
        end
      end
      if self.current_leaf_name_ then
        buf[#buf + 1] = self.current_leaf_name_
      end
      return buf
    end;

    -- Private method
    unset_leaf_name_ = function(self, ...)
      method_arguments(self)
      self.current_leaf_name_ = nil
      return ...
    end;

    walk_data_with_schema = function(self, schema, data)
      method_arguments(
          self,
          "table", schema,
          "table", data
        )

      assert(#schema > 0)

      self:reset()
      self:set_data(data)

      self:walk_schema_(schema)

      return self
    end;

    -- Private method
    walk_schema_ = function(self, schema)
      for i = 1, #schema do
        walk_tagged_tree(schema[i], self, "id")
      end
    end;

    --
    factory_ = nil;
    get_current_path_closure_ = nil;
    --
    data_ = nil;
    current_path_ = { };
    current_leaf_name_ = nil;
    context_ = nil;
    checker_ = nil;
  };

  types.down = setmetatable(
      { },
      {
        __index = function(t, k)
          types.checker_:fail("[down] unknown tag " .. tostring(k))
          return nil
        end;
      }
    );
  types.up = setmetatable(
      { },
      {
        __index = function(t, k)
          types.checker_:fail("[up] unknown tag " .. tostring(k))
          return nil
        end;
      }
    );

  local get_value = function(
      self,
      types_schema,
      data_schema,
      data,
      key
    )
    method_arguments(
        self,
        "table", types_schema,
        "table", data_schema,
        "table", data
        -- key may be of any type
      )
    assert(key ~= nil)

    local value = data[key]
    if value == nil and data_schema.default ~= nil then
      value = tclone(data_schema.default)
    end
    return value
  end

  local walkers =
  {
    up =
    {
      ["types:down"] = function(self, info)
        info.handler = assert_is_function(info.handler or do_nothing)

        local old_handler = rawget(self.types_.down, info.name)
        assert(old_handler == nil or old_handler == do_nothing)

        self.types_.down[info.name] = function(self, data)
          if #self.current_path_ == 0 then
            self.checker_:fail("item must not be at root")
            return "break"
          end

          local scope = self.current_path_[#self.current_path_]
          assert(scope ~= nil)

          self.current_leaf_name_ = data.name

          return self:unset_leaf_name_(info.handler(
              self.context_,
              data,
              get_value(self, info, data, scope.node, data.name)
            ))
        end

        -- Avoiding triggering __index error handler
        self.types_.up[info.name] = do_nothing
      end;

      ["types:up"] = function(self, info)
        info.handler = assert_is_function(info.handler or do_nothing)

        local old_handler = rawget(self.types_.up, info.name)
        assert(old_handler == nil or old_handler == do_nothing)

        self.types_.up[info.name] = function(self, data)
          if #self.current_path_ == 0 then
            self.checker_:fail("item must not be at root")
            return "break"
          end

          local scope = self.current_path_[#self.current_path_]
          assert(scope ~= nil)

          self.current_leaf_name_ = data.name

          return self:unset_leaf_name_(info.handler(
              self.context_,
              data,
              get_value(self, info, data, scope.node, data.name)
            ))
        end

        -- Avoiding triggering __index error handler
        self.types_.down[info.name] = do_nothing
      end;

      ["types:variant"] = function(self, info)
        info.handler = assert_is_function(info.handler or do_nothing)

        local walkers = self -- Note alias

        local vtag_key = info.tag_key or "name"
        local vdata_key = info.data_key or "param"

        assert_is_nil(rawget(self.types_.down, info.name))
        self.types_.down[info.name] = function(self, data)
          local child_schema = data.variants
          if not child_schema then
            self.checker_:fail(
                "bad variant `" .. tostring(data.name) .. "' definition:"
             .. " missing `variants' field"
              )
            return "break"
          end

          -- Why?
          if #self.current_path_ == 0 then
            self.checker_:fail("variant must not be at root")
            return "break"
          end

          local node = get_value(
              self,
              info,
              data,
              self.current_path_[#self.current_path_].node,
              data.name
            )
          if node == nil then
            self.checker_:fail("`" .. tostring(data.name) .. "' is missing")
            return "break"
          end
          if not is_table(node) then
            self.checker_:fail("`" .. tostring(data.name) .. "' is not table")
            return "break"
          end

          local variant = node

          local vtag = variant[vtag_key]
          if vtag == nil then
            self.current_leaf_name_ = data.name -- Hack
            self.checker_:fail(
                "tag field `" .. tostring(vtag_key) .. "' is missing"
              )
            self.current_leaf_name_ = nil
            return "break"
          end

          local vdata = variant[vdata_key]
          if vdata == nil then
            self.current_leaf_name_ = data.name -- Hack
            self.checker_:fail(
                "data field `" .. tostring(vdata_key) .. "' is missing"
              )
            self.current_leaf_name_ = nil
            return "break"
          end

          local vschema = child_schema[vtag]
          if not vschema then
            self.current_leaf_name_ = data.name -- Hack
            self.checker_:fail(
                "bad tag field `" .. tostring(vtag_key) .. "' value `"
             .. tostring(vtag) .. "':" .. " expected one of { "
             .. table_concat(tkeys(child_schema), " | ") .. " }"
              )
            self.current_leaf_name_ = nil
            return "break"
          end

          local scope =
          {
            name = data.name;
            node = variant;
          }
          table_insert(self.current_path_, scope)

          self.current_leaf_name_ = nil
          self:unset_leaf_name_((info.down_handler or info.handler)(
              self.context_,
              data,
              scope.node
            ))

          do
            local scope =
            {
              name = vdata_key;
              node = vdata;
            }
            table_insert(self.current_path_, scope)
            self.current_leaf_name_ = nil

            self:walk_schema_(vschema)

            assert(table_remove(self.current_path_) == scope)
          end

          self.current_leaf_name_ = nil
          self:unset_leaf_name_((info.up_handler or do_nothing)(
              self.context_,
              data,
              scope.node
            ))

          assert(table_remove(self.current_path_) == scope)

          return "break" -- Handled child nodes manually
        end
      end;

      ["types:ilist"] = function(self, info)
        info.handler = assert_is_function(info.handler or do_nothing)

        local walkers = self -- Note alias

        assert_is_nil(rawget(self.types_.down, info.name))
        self.types_.down[info.name] = function(self, data)
          local child_schema = data

          -- Why?
          if #self.current_path_ == 0 then
            self.checker_:fail("ilist must not be at root")
            return "break"
          end

          local node = get_value(
              self,
              info,
              data,
              self.current_path_[#self.current_path_].node,
              data.name
            )
          if node == nil then
            self.checker_:fail("`" .. tostring(data.name) .. "' is missing")
            return "break"
          end
          if not is_table(node) then
            self.checker_:fail("`" .. tostring(data.name) .. "' is not table")
            return "break"
          end

          local scope =
          {
            name = data.name;
            node = node;
          }
          table_insert(self.current_path_, scope)

          self.current_leaf_name_ = nil
          self:unset_leaf_name_((info.down_handler or info.handler)(
              self.context_,
              data,
              scope.node
            ))

          local list = scope.node
          for i = 1, #list do
            local item = list[i]

            local scope =
            {
              name = tostring(i);
              node = item;
            }
            table_insert(self.current_path_, scope)
            self.current_leaf_name_ = nil

            self:walk_schema_(child_schema)

            assert(table_remove(self.current_path_) == scope)
          end

          self.current_leaf_name_ = nil
          self:unset_leaf_name_((info.up_handler or do_nothing)(
              self.context_,
              data,
              scope.node
            ))

          assert(table_remove(self.current_path_) == scope)

          return "break" -- Handled child nodes manually
        end
      end;

      ["types:node"] = function(self, info)
        info.handler = assert_is_function(info.handler or do_nothing)

        assert_is_nil(rawget(self.types_.down, info.name))
        self.types_.down[info.name] = function(self, data)
          if #self.current_path_ == 0 then
            self.checker_:fail("node must not be at root")
            return "break"
          end

          local node = get_value(
              self,
              info,
              data,
              self.current_path_[#self.current_path_].node,
              data.name
            )
          if node == nil then
            self.checker_:fail("`" .. tostring(data.name) .. "' is missing")
            return "break"
          end
          if not is_table(node) then
            self.checker_:fail("`" .. tostring(data.name) .. "' is not table")
            return "break"
          end

          local scope =
          {
            name = data.name;
            node = node;
          }

          table_insert(self.current_path_, scope)

          self.current_leaf_name_ = nil

          return self:unset_leaf_name_((info.down_handler or info.handler)(
              self.context_,
              data,
              scope.node
            ))
        end

        assert_is_nil(rawget(self.types_.up, info.name))
        self.types_.up[info.name] = function(self, data)
          assert(#self.current_path_ ~= 0)
          local scope = table_remove(self.current_path_)
          assert(scope ~= nil)
          assert(scope.name == data.name)

          self.current_leaf_name_ = nil

          return self:unset_leaf_name_((info.up_handler or do_nothing)(
              self.context_,
              data,
              scope.node
            ))
        end
      end;

      ["types:root"] = function(self, info)
        assert(not self.root_defined_, "duplicate root definition")
        self.root_defined_ = true

        info.handler = assert_is_function(info.handler or do_nothing)
        info.name = info.name or ""

        assert_is_nil(rawget(self.types_.down, info.name))
        self.types_.down[info.name] = function(self, data)
          assert(#self.current_path_ == 0)

          local scope =
          {
            name = data.name;
            node = self.data_;
          }

          table_insert(self.current_path_, scope)

          self.current_leaf_name_ = nil

          return self:unset_leaf_name_((info.down_handler or info.handler)(
              self.context_,
              data,
              scope.node
            ))
        end

        assert_is_nil(rawget(self.types_.up, info.name))
        self.types_.up[info.name] = function(self, data)
          assert(#self.current_path_ == 1)
          local scope = table_remove(self.current_path_)
          assert(scope ~= nil)
          assert(scope.name == data.name)

          self.current_leaf_name_ = nil

          return self:unset_leaf_name_((info.up_handler or do_nothing)(
              self.context_,
              data,
              scope.node
            ))
        end
     end;

     -- Factory receives two arguments:
     -- 1. checker object; prefer to use it for error handling.
     -- 2. get_current_path function,
     --    which returns as table current path in data (including leafs).
     --    Path is calculated on each call of the function.
     ["types:factory"] = function(self, data)
        assert_is_nil(self.factory_)
        self.types_.factory_ = assert_is_function(data.handler)
      end;
    };
    --
    types_ = types;
    root_defined_ = false;
  }

  for i = 1, #schema do
    walk_tagged_tree(schema[i], walkers, "id")
  end

  types.factory_ = types.factory_ or function() return { } end

  types.get_current_path_closure_ = function()
    return types:get_current_path()
  end

  types:reset()

  assert(walkers.root_defined_, "types:root must be defined")

  return types
end

--------------------------------------------------------------------------------

--[[
-- TODO: Uncomment and move to tests
do
  local data =
  {
    ["k"] =
    {
      v = 3;
    },
    value = 12;
  }

  local types = load_data_walkers(function()
    -- TODO: `types "name" .down (function() end)' is fancier.
    types:down "schema:three" (function(self, info, value)
      self:ensure_equals(value, 3)
    end)

    types:down "schema:twelve" (function(self, info, value)
      self:ensure_equals(value, 12)
    end)

    types:node "schema:node"

    types:root "schema:root"

    types:factory (function(checker, get_current_path)

      return
      {
        ensure_equals = function(self, actual, expected)
          if actual ~= expected then
            self.checker_:fail(
                "actual: " .. tostring(actual)
             .. " expected: " .. tostring(expected)
              )
          end
          return actual
        end;
        --
        checker_ = checker;
      }
    end)
  end)

  local schema = load_data_schema(function()
    schema:root "r"
    {
      schema:node "k"
      {
        schema:three "v";
      };

      schema:twelve "value";
    }
  end)

  assert(types:walk_data_with_schema(schema, data):get_checker():result())

  error("OK")
end
--]]

--------------------------------------------------------------------------------

return
{
  load_data_walkers = load_data_walkers;
  load_data_schema = load_data_schema;
}
