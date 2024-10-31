local lpeg = require "lpeg"
local R, S, P, C, V = lpeg.R, lpeg.S, lpeg.P, lpeg.C, lpeg.V
local Cg, Ct = lpeg.Cg, lpeg.Ct


local function create_grammar(operators)
    local grammar
    grammar = P{
        "expression",
        expression = Ct(V("operation") * (ss * V("operation"))^0),
        operation = V("setter") + V("getter") + V("value"),
        setter = Ct(V("set_op") * ss * V("args")),
        getter = Ct(V("get_op") * ss * V("args")^-1),
        value = num_cap,
        args = Ct(V("value") + V("getter") + V("variable"))^1,
        variable = C(abc^1),
        set_op = C(P(operators.setters)),
        get_op = C(P(operators.getters)),
    } / function(parsed)
        return evaluate(parsed)
    end
    return grammar
end

local function evaluate(parsed)
    local results = {}
    for _, op in ipairs(parsed) do
        if type(op) == "table" then
            if operators[op[1]] then
                table.insert(results, operators[op[1]](table.unpack(op[2])))
            else
                error("Unknown operator: " .. op[1])
            end
        end
    end
    return results
end

-- Operators definition
local operators = {
    setters = S("CV G.P A"),
    getters = S("CV N A ADD G.P *"),
    ["CV"] = function(cv, value)
        if value then
            return "Setting CV " .. cv .. " to " .. value
        else
            return "Getting CV " .. cv .. ": 5.0"
        end
    end,
    ["G.P"] = function(x, y, value)
        return "Setting G.P " .. x .. " " .. y .. " to " .. value
    end,
    ["A"] = function(value)
        if value then
            return "Setting variable A to " .. value
        else
            return "Getting variable A: 3"
        end
    end,
    ["N"] = function(note)
        return "Getting note " .. note .. ": 1.0"
    end,
    ["ADD"] = function(a, b)
        return "Adding " .. a .. " and " .. b .. ": " .. (a + b)
    end,
    ["*"] = function(a, b)
        return "Multiplying " .. a .. " and " .. b .. ": " .. (a * b)
    end,
}

local grammar = create_grammar(operators)

function evaluate_line(context, grammar, text)
    local result = lpeg.match(grammar, text)
    if result then
        return result
    else
        error("Invalid expression: " .. text)
    end
end

-- Tests
local function run_tests()
    local test_cases = {
        {"CV 1 5", {"Setting CV 1 to 5"}},
        {"G.P 20 30 100", {"Setting G.P 20 30 to 100"}},
        {"A 5", {"Setting variable A to 5"}},
        {"CV 1", {"Getting CV 1: 5.0"}},
        {"N 13", {"Getting note 13: 1.0"}},
        {"ADD 4 6", {"Adding 4 and 6: 10"}},
        {"* 40 55", {"Multiplying 40 and 55: 2200"}},
    }
    for _, case in ipairs(test_cases) do
        local result = evaluate_line(nil, grammar, case[1])
        assert(table.concat(result, ", ") == table.concat(case[2], ", "), "Test failed for: " .. case[1])
    end
    print("All tests passed")
end

run_tests()
print("DONE")