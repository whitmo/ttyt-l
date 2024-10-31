-- Definition of default teletype grammar
-- ala https://github.com/monome/teletype/blob/main/src/scanner.rl

local lpeg = require "lpeg"
local grammar = {}
local obju = require "objutil"

function Grammar:new(o)
   local defaults = {}
   o = obju:instance_ctor(grammar, {}, grammar)
   return o
end


-- lpeg patten for capturing posfix addition
-- + 1 2 => 3
-- + a b => a + b


return grammar
-- /opt/homebrew/lib/lua/5.4/
