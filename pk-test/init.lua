--------------------------------------------------------------------------------
-- Common things which must be included into each test
--------------------------------------------------------------------------------

-- Note: must be done before "dofile('lua-nucleo/strict.lua')"
dofile('pk-test/require.lua')

--------------------------------------------------------------------------------

local make_suite = ...
assert(type(make_suite) == "function")

--------------------------------------------------------------------------------

dofile('lua-nucleo/strict.lua')

local import_set_base_path, import_get_path
do
  local base_path = ""

  import_set_base_path = function(new_path)
    base_path = new_path
  end

  import_get_path = function(filename)
    return base_path .. filename
  end
end

assert(loadfile('lua-nucleo/import.lua'))(import_get_path)

--------------------------------------------------------------------------------

do
  local init_test_logging_system
        = import 'pk-test/log.lua'
        {
          'init_test_logging_system'
        }

  init_test_logging_system()
end

--------------------------------------------------------------------------------

return make_suite, import_set_base_path
