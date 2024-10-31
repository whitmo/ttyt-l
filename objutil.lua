-- OO/Eventing helpers

local utils = {}
local M = require 'mediator'

-- Instance constructor
function utils:instance_ctor(o, defaults, instance)
   local o = o or {}

   setmetatable(o, instance)
   instance.__index = instance

   if defaults == nil then
      defaults = {}
   end

   for k,v in pairs(defaults) do
      if o[k] == nil then
	 o[k] = v
      end
   end

   return o
end

-- Eventing metachannels
utils['event'] = {
   keyboard = M(),
   system = M()
}


-- add split function to string
function string:split( inSplitPattern )
   local outResults = {}
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )

   while theSplitStart do
      table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   end

   table.insert( outResults, string.sub( self, theStart ) )
   return outResults
end

return utils
