-- Start a command line

tu = require "tabutil"
local ttyt = require "ttbase"
local objutil = require "objutil"
local kc = require "keycodes"
local event = objutil.event
local globs = {}

function init()
   tty = ttyt:new()
   globs.tty = tty
   globs.event = event
end

-- default "drawer"
function redraw()
   tty.cmdline:render()
end

local red = {r = 168, g = 35, b = 60}

-- react to clicking on the seamstress window!
function screen.click(x, y, state, button)
  event.system:publish({"click"}, {x=x, y=y, state=state, button=button})
end

-- keyboard input handler callback
function screen.key(char, modifiers, is_repeat, state)
   local keytype = type(char)

   if keytype == "string" and tu.contains(modifiers, "shift") then
      char = kc.shifted[char]
   end

   local data = {
      char=char,
      modifiers=modifiers,
      is_repeat=is_repeat,
      state=state
   }
   globs.event.keyboard:publish({keytype}, data)
end


return tty
