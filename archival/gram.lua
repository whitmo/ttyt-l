local lpeg = require "lpeg"
local obju = require "objutil"
local R, S, P, C, V = lpeg.R, lpeg.S, lpeg.P, lpeg.C, lpeg.V
local Cg, Ct = lpeg.Cg, lpeg.Ct
local tab = {}

local locale = lpeg.locale()
local ss = locale.space^0
local space = locale.space
local nl = lpeg.S("\n")^1
local abc = locale.alpha

local opstr = abc^1*R("09")^0
local str_op = opstr*(S(".")*opstr)^-1 -- ex: "CV1.SLEW" or "CV1"
local sym_op = S("$+-/%!")
local op = (str_op + sym_op)

-- (S("$+-/%!") + P(abc^1*R("09")*(S(".")*abc^1)^-1))*ss

local number = P"-"^-1 * R("09")^1 * (S(".") * R("09")^1)^-1
local num_cap = C(number / tonumber)

local termin = (nl or S(";") or P(-1))


function pp(val, ...)
   if type(val) == "nil" then
      return print("nil")
   end

   if type(val) == "table" then
      for k, v in pairs(val) do
	 print(k .. "\t" .. tostring(v))
      end
      return 0
   end
   return print(val)
end

local function accum(t)
   store = t
   function add(k, ...)
      store[k] = {...}
    end
   return add
end

-- OpMode = {}
-- function OpMode:new (o)
--    local defaults = {
--       name = "READ",
--       matcher = P(-1),
--       description = "Returns a value, takes no arguments"
--    }
--    o = obju:instance_ctor(o, defaults, self)
--    return o
-- end

-- value = Cg(number / tonumber, "val")
-- ops_modes = {
--    read = OpMode:new{name = "READ", matcher = op},
--    write = OpMode:new{name = "WRITE", matcher = op * space^1 * value},
-- }

-- ops_modes.readwrite = OpMode:new{
--    name = "READWRITE",
--    matcher = ops_mode.READ.cpatt() + ops_mode.WRITE.matcher.cpatt()
-- }

-- Operator = {}
-- function Operator:new(o)
--    local defaults = {
--       name = nil,
--       aliases = {}
--    }
--    defaults.matcher = P(defaults.name)
--    o = obju:instance_ctor(o, defaults, self)
--    return o
-- end






local Context = {}
function Context:new(o)
   local defaults = {
      state = {},
      ops = {

      }

   }
   o = obju:instance_ctor(o, defaults, self)

   return o
end


local t = {}
local G = lpeg.P{
   "EXP";
   EXP = Ct(V"OP" or V"OP"*space^-1*V"TERM"^0)*termin^-1,
   OP = Cg(op, "op"),
   TERM = V"EXP" + Cg(V"NUM", "val"),
   NUM = Cg(number / tonumber, "num")*space^-1,
}


-- term2_match = (Ct(Cg((locale.alnum^1*locale.space^0)^1, "sub")*Cg(term^0, "term"))):match("A") -- returns terminator and a string for everything before it

-- term = space^0*Cg(S(";\n")*P(-1), "exp_terminus")


term2 = S(" ;\n")^-1*P(-1)
G2 = lpeg.P{
   "EXP";
   EXP=Ct(V"SETGET"*V"ARGS")*V"TERMINUS"^-1,
   NUM = Cg(number / tonumber, "num")*(space^1 or V"TERMINUS"),
   SETGET = V"SETTER" + V"GETTER",
   ARGS=Cg(Ct(V"NUM"^0 + V"GETTER"^0), 'args'),
   TERMINUS = Cg(term2, "terminus"),
   SETTER=Cg(op, "setter")*space^1,
   GETTER=Cg(op, "getter")*(V"TERMINUS" + space^1),

}

pp(G2:match("ALL 1 1 B 2 2"))
pp(G2:match("ALL"))




out = lpeg.match(G2, "ADD A 1")

if out then
   pp(out)
end


return {grammar = G, context = Context, OpMode = OpMode}
