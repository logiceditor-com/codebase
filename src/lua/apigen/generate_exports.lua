--------------------------------------------------------------------------------
-- generate_exports.lua: api exports generator
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

local make_concatter
      = import 'lua-nucleo/string.lua'
      {
        'make_concatter'
      }

local make_checker
      = import 'lua-nucleo/checker.lua'
      {
        'make_checker'
      }

local tkeys
      = import 'lua-nucleo/table-utils.lua'
      {
        'tkeys'
      }

local create_path_to_file,
      write_file
      = import 'lua-aplicado/filesystem.lua'
      {
        'create_path_to_file',
        'write_file'
      }

local walk_tagged_tree
      = import 'pk-core/tagged-tree.lua'
      {
        'walk_tagged_tree'
      }

local make_loggers
      = import 'pk-core/log.lua'
      {
        'make_loggers'
      }

local list_globals_in_handler,
      classify_globals,
      generate_globals_header
      = import 'apigen/api_globals.lua'
      {
        'list_globals_in_handler',
        'classify_globals',
        'generate_globals_header'
      }

--------------------------------------------------------------------------------

local log, dbg, spam, log_error = make_loggers("generate_exports", "GEX")

--------------------------------------------------------------------------------

local generate_exports
do
  local down = { }
  do
    local url_down = function(walkers, data)
      local cat, concat = make_concatter()
      walkers.cat_ = cat
      walkers.concat_ = concat
      walkers.current_url_ = { }

      local log_module_name = "handlers" .. data.filename

      -- First character is slash
      -- TODO: Get that from somewhere!
      local log_short_name = data.filename:sub(2, 4):upper()

      -- TODO: Create loggers on-demand, like all other globals and upvalues

      walkers.cat_ [[
--------------------------------------------------------------------------------
-- ]] (data.filename:gsub("^/", "")) [[: generated url handler
--------------------------------------------------------------------------------
-- WARNING! Do not change manually.
-- Generated by apigen.lua
--------------------------------------------------------------------------------

local log, dbg, spam, log_error
    = import 'pk-core/log.lua' { 'make_loggers' } (
        "]] (log_module_name)
  [[", "]] (log_short_name) [["
      )

]]
    end
    down["api:export"] = url_down
  end

  local up = { }
  do
   local extract_handler_source = function(handler_fn, tag)
      arguments(
          "function", handler_fn,
          "string", tag
        )

      local info = debug.getinfo(handler_fn)
      assert(info.what == "Lua")

      local filename = info.source:gsub("^@", "")
      local linefrom = info.linedefined
      local lineto = info.lastlinedefined

      local cat, concat = make_concatter()

      -- TODO: Do proper parsing.
      --       Should support other functions, defined on the same line etc.
      local file = assert(io.open(filename, "r"))
      local lineno = 0
      local indent = nil

      for line in file:lines() do
        lineno = lineno + 1

        -- TODO: Fragile! At least fail if substitutions are unsuccessful!
        if lineno > linefrom and lineno < lineto then
          if indent == nil then
            indent = line:match("^(%s+)") -- Unindent by the first line indentation
            if not indent then
              indent = false
            end
          end

          if indent then
            line = line:gsub("^" .. indent, "")
          end

          cat (line) "\n"
        end

        if lineno > lineto then
          break
        end
      end
      file:close()
      file = nil

      return concat()
    end

    -- TODO: Fail instead
    local default_handler_text = [[
-- Export function not found!
]]
    local url_up = function(walkers, data)

      local checker = make_checker()
      walkers.api_globals_ = tkeys(
          list_globals_in_handler(
              checker,
              tostring(data.id)
           .. (data.name and (" '" .. tostring(data.name) .. "'") or ""),
              data.handler
            )
        )
      assert(checker:result())

      walkers.handler_text_ = extract_handler_source(
          data.handler,
          data.id
        )

      local filename = walkers.out_file_root_ .. walkers.handlers_dir_name_ ..
        "/" .. data.filename
      log("generating", data.filename, "to", filename)
      assert(create_path_to_file(filename))

      -- TODO: Support upvalues!
      local global_overrides = walkers.global_overrides_ or { }
      -- TODO: Create loggers on demand only!
      global_overrides["log"] = true
      global_overrides["dbg"] = true
      global_overrides["spam"] = true
      global_overrides["log_error"] = true

      walkers.cat_ [[
]] (
    generate_globals_header(
        classify_globals(
            walkers.known_exports_,
            walkers.allowed_requires_,
            walkers.allowed_globals_,
            walkers.api_globals_ or { },
            global_overrides
          )
      )
  ) [[
]](walkers.handler_text_)[[
  return
  {
]]
      for i = 1, #data.exports do
        walkers.cat_ [[    ]] (data.exports[i]) [[ = ]] (data.exports[i]) [[;
]]
      end
      walkers.cat_[[
  }
]]
      assert(
          write_file(
              filename,
              walkers.concat_()
            )
        )

      walkers.cat_ = nil
      walkers.concat_ = nil
      walkers.handler_text_ = nil
      walkers.api_globals_ = nil
      walkers.global_overrides_ = nil
      walkers.current_url_ = nil
      walkers.returns_ = ""
    end

    up["api:export"] = url_up
  end

  generate_exports = function(
      schema,
      out_file_root,
      handlers_dir_name,
      known_exports,
      allowed_requires,
      allowed_globals
    )
    arguments(
        "table", schema,
        "string", out_file_root,
        "string", handlers_dir_name,
        "table", known_exports,
        "table", allowed_requires,
        "table", allowed_globals
      )

    local walkers =
    {
      down = down;
      up = up;
      --
      cat_ = nil;
      current_url_ = nil;
      handler_text_ = nil;
      id_ = nil;
      name_ = nil;
      out_file_root_ = out_file_root;
      handlers_dir_name_ = handlers_dir_name;
      api_globals_ = nil;
      global_overrides_ = nil;
      returns_ = "";
      --
      known_exports_ = known_exports;
      allowed_requires_ = allowed_requires;
      allowed_globals_ = allowed_globals;
    }

    for i = 1, #schema do
      walk_tagged_tree(schema[i], walkers, "id")
    end
  end
end

--------------------------------------------------------------------------------

return
{
  generate_exports = generate_exports;
}
