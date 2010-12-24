--------------------------------------------------------------------------------
-- profile.lua: exports profile
--------------------------------------------------------------------------------

local tset = import 'lua-nucleo/table-utils.lua' { 'tset' }

--------------------------------------------------------------------------------

local PROFILE = { }

--------------------------------------------------------------------------------

PROFILE.skip = setmetatable(tset
{
  -- Nothing to skip
}, {
  __index = function(t, k)
    -- Excluding files outside of pk-admin/ and inside pk-admin/code
    local v = (not k:match("^pk%-admin/")) or k:match("^pk%-admin/code/")
    t[k] = v
    return v
  end;
})

--------------------------------------------------------------------------------

return PROFILE
