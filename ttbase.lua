-- teletype classes

local objutil = require "objutil"
local TTyt = {}
local tu = require "tabutil"
-- local default_grammar = require "default_grammar"

-- teletype container

local UIPrompt = {}

function UIPrompt:new (o)
   defaults = {
      prompt = ">> ",
      history = {},
      focussed = false,
      position = {x = 2, y = screen.height - 10},
      txtcolor = {r = 255, g = 255, b = 255}
   }
   o = objutil:instance_ctor(o, defaults, self)
   o.active_text = ""
   return o
end

function UIPrompt:txt_entry (data)
   tu.print(data.modifiers)
   self.active_text = self.active_text..data.char
   self:render()
end

-- redraw this prompt
function UIPrompt:render()
   local color = self.txtcolor
   screen.clear()
   screen.move(self.position.x, self.position.y)

   screen.color(138, 5, 5)
   screen.rect(self.position.x, self.position.y, 1000, 100)
   screen.color(color.r, color.g, color.b)

   screen.text(self.prompt..self.active_text)
   screen.color(0, 0, 0)
   screen.update()
end

function TTyt:new (o)
   local defaults = {
      cmdline = UIPrompt:new(),
      parser = {},
      behavior_registry = {},
      event = objutil.event
   }

   o = objutil:instance_ctor(o, defaults, self)

   local onpress = function(data) return data.state == 1 end

   o.txt_sub = o.event.keyboard:subscribe(
      {"string"},
      function(data) o.cmdline:txt_entry(data) end,
      {predicate = onpress}
   )

   o.txt_special_sub = o.event.keyboard:subscribe(
      {"table"},
      function(data) o:redispatch_key(data) end,
      {predicate = onpress}
   )

   return o
end

function TTyt:dispatch_cmd(cmd)
   print(cmd)
   -- if cmd_name == "help" then
   --    self:cmd_help(cmd_args)
   -- elseif cmd_name == "exit" then
   --    self:cmd_exit(cmd_args)
   -- elseif cmd_name == "clear" then
   --    self:cmd_clear(cmd_args)
   -- else
   --    self:cmd_unknown(cmd_args)
   -- end
end

function TTyt:redispatch_key(data)
   local key = data.char.name
   if key == "backspace" then
      self.cmdline.active_text = string.sub(self.cmdline.active_text, 1, -2)
   elseif key == "return" then
      self:dispatch_cmd(self.cmdline.active_text)
      self.cmdline.active_text = ""
   end

   self.cmdline:render()
end

return TTyt
