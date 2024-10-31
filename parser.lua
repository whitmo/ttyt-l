local lpeg = require 'lpeg'

local P, V, S, R, C, Ct, Cg = lpeg.P, lpeg.V, lpeg.S, lpeg.R, lpeg.C, lpeg.Ct, lpeg.Cg

-- Registry for language elements
local Registry = {
    ops = {},    -- Operators like TR.PULSE, CV
    mods = {},   -- Modifiers like IF, L

    register_op = function(self, name, pattern, executor)
        self.ops[name] = {
            pattern = pattern,
            execute = executor
        }
    end,

    register_mod = function(self, name, pattern, handler)
        self.mods[name] = {
            pattern = pattern,
            handle = handler
        }
    end,
}
local n_limit = {min = -32768, max = 32767}
-- Basic patterns
local space = S(' \t\n')^0
local digits = R('09')^1
local sign = S('+-')^-1
local number = (sign * digits) / function(n)
    local num = tonumber(n)
    assert(num >= n_limit.min and num <= n_limit.max, "Number out of range")
    return num
end

local G = P{
    "Command",

    Command = V"ConditionalCommand" + V"SimpleCommand",

    ConditionalCommand = Ct(
        Cg(V"Pre", "pre") *
        V"PreSep" *
        Cg(V"Post", "post")
    ),

    -- Ensure SimpleCommand wraps everything properly
    SimpleCommand = Ct(
        Cg(V"Post", "post")
    ),

    Pre = Ct(
        V"Modifier" * space * V"Expression"
    ),

    -- Ensure Post always returns an array of commands
    Post = Ct(
        V"SingleCommand" *
        (V"SubSep" * V"SingleCommand")^0
    ),

    -- Always wrap command in a table
    SingleCommand = Ct(
        V"Operator" * (space * V"Expression")^0
    ),

    Operator = C(R('AZ', 'az') * (R('AZ', 'az', '09') + P'.')^0),
    Modifier = C(R('AZ', 'az')^1),
    Expression = V"Operator" + V"Number",
    Number = number,

    PreSep = space * P":" * space,
    SubSep = space * P";" * space
}

-- Execution context
local Context = {
    vars = {},
    triggers = {},

    get_var = function(self, name)
        return self.vars[name]
    end,

    set_var = function(self, name, value)
        self.vars[name] = value
    end
}

-- Updated Executor
local Executor = {
    execute = function(self, ast, context)
        if not ast then return nil end

        -- Handle Pre section if it exists
        if ast.pre then
            local mod = Registry.mods[ast.pre[1]]
            if mod and mod.handle then
                if mod.handle(context, ast.pre[2]) then
                    self:execute_post(ast.post, context)
                end
            end
        else
            -- No Pre section, just execute Post
            self:execute_post(ast.post, context)
        end
    end,

    execute_post = function(self, post, context)
        -- Ensure post is properly formatted
        if not post then return end

        for _, sub in ipairs(post) do
            -- Skip if sub is not a table
            if type(sub) ~= "table" then
                print("Warning: Malformed command", sub)
                goto continue
            end

            local op_name = sub[1]
            local op = Registry.ops[op_name]
            if op and op.execute then
                -- Remove the operator name and pass the rest as args
                local args = {}
                for i = 2, #sub do
                    args[i-1] = sub[i]
                end
                op.execute(context, table.unpack(args))
            end
            ::continue::
        end
    end
}


-- Parser function (moved up)
local function parse(input)
    return G:match(input)
end

-- Example operator registrations
Registry:register_op("X",
		     P"X",
    function(ctx, val)
        ctx:set_var("X", tonumber(val) or 0)
    end
)

Registry:register_op("Y",
    P"Y",
    function(ctx, val)
        ctx:set_var("Y", tonumber(val) or 0)
    end
)

Registry:register_op("Z",
    P"Z",
    function(ctx, val)
        ctx:set_var("Z", tonumber(val) or 0)
    end
)

Registry:register_op("TR.P",
    P"TR.P",
    function(ctx, channel)
        print(string.format("Pulse trigger %d", channel))
    end
)

Registry:register_op("CV",
    P"CV",
    function(ctx, channel, note_type, note_val)
        -- Handle both CV 1 N 60 and CV 1 V 5 formats
        local value = note_val
        if note_type == "N" then
            -- Convert note number to voltage if needed
            value = note_val / 12  -- Simple conversion, adjust as needed
        end
        print(string.format("Set CV %d to %f V (note: %s %s)",
            channel, value, note_type, tostring(note_val)))
    end
)

Registry:register_mod("IF",
    P"IF",
    function(ctx, condition)
        return ctx:get_var(condition) ~= 0
    end
)

Registry:register_mod("L",
    P"L",
    function(ctx, count)
        return tonumber(count) > 0
    end
)


-- Test function with better error handling
local function test_parser()
    local test_cases = {
        -- Simple commands
        "X 0",
        "X 0; Y 1; Z 2",
        -- Conditional commands with sub-commands
        "IF X: CV 1 N 60; TR.P 1",
        "IF Y: TR.P 1; TR.P 2; TR.P 3",
        -- Should fail (invalid sub-command usage)
        "X 1; IF X: TR.PULSE 1",
        -- More complex examples
        "L 4: CV 1 N 60; CV 2 N 64; TR.P 1",
    }

    local ctx = Context
    ctx:set_var("X", 1)
    ctx:set_var("Y", 1)

    for _, test in ipairs(test_cases) do
        print("\nParsing:", test)
        local ast = parse(test)
        if ast then
            print("Success!")
            print("AST:", require('inspect')(ast))
            -- Try to execute if parsing succeeded
            local success, err = pcall(function()
                Executor:execute(ast, ctx)
            end)
            if not success then
                print("Execution failed:", err)
            end
        else
            print("Parse failed - invalid syntax")
        end
    end
end



return {
    Registry = Registry,
    Context = Context,
    Executor = Executor,
    parse = parse,
    test_parser = test_parser
}
