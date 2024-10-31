local lpeg = require "lpeg"

local P, C, Ct, V = lpeg.P, lpeg.C, lpeg.Ct, lpeg.V

-- Define operators and their corresponding functions
local operators = {
  ADD = function(a, b) return a + b end,
  SUB = function(a, b) return a - b end,
  CV1 = function() return { some_voltage = 42 } end,
}

-- Define the grammar
local locale = lpeg.locale()
local space = locale.space^0
local word = locale.alpha^1
local number = lpeg.C(lpeg.R("09")^1) / tonumber
local value = number + word
local expression

expression = lpeg.P {
  "expr",
  expr = Ct(operator * space * (value + (space * V"expr")))^0,
  value = C(value),
}

local function evaluate(parsed)
  local operator = parsed[1]
  local args = {}
  for i = 2, #parsed do
    if type(parsed[i]) == "table" then
      args[i - 1] = evaluate(parsed[i])
    else
      args[i - 1] = parsed[i]
    end
  end
  local operatorFunc = operators[operator]
  if operatorFunc then
    return operatorFunc(table.unpack(args))
  else
    return nil  -- Handle unknown operators
  end
end

-- Example usage
local input = "ADD 1 SUB 9 2"
local parsed = expression:match(input)
local result = evaluate(parsed)
print(result)
