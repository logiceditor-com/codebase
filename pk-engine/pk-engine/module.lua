--------------------------------------------------------------------------------
-- module.lua: module bootstrapper
--------------------------------------------------------------------------------

require 'lua-nucleo.module'
require 'lua-aplicado.module'

-- You may also want to require 'lua-nucleo.strict'.

-- TODO: Verify this list!
require 'copas' -- Should be loaded first
require 'posix'
require 'socket'
require 'socket.http'
require 'luabins'
require 'socket.url'
require 'md5'
require 'luasql.mysql'
require 'uuid'
require 'lfs'
require 'ev'
require 'ltn12'
require 'random'
