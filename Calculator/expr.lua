--- Arithmetic on a string: tokenizer plus recursive descent.
--- Kept apart from the window so the parsing reads on its own.

local Expr = {}

local functions = {
   sqrt = math.sqrt,
   abs = math.abs,
   floor = math.floor,
   ceil = math.ceil,
   sin = math.sin,
   cos = math.cos,
   tan = math.tan,
   exp = math.exp,
   log = math.log,
   round = function(x) return math.floor(x + 0.5) end,
}

--- Level 0 keeps the file and line out of the message shown to the player.
local function fail(message)
   error(message, 0)
end

local function tokenize(src)
   local tokens = {}
   local i = 1

   while i <= #src do
      local rest = src:sub(i)
      local space = rest:match("^%s+")
      local number = rest:match("^%d+%.?%d*[eE][-+]?%d+")
         or rest:match("^%.%d+[eE][-+]?%d+")
         or rest:match("^%d+%.?%d*")
         or rest:match("^%.%d+")
      local name = rest:match("^[%a_][%w_]*")

      if space then
         i = i + #space
      elseif number then
         tokens[#tokens + 1] = { kind = "number", value = tonumber(number) }
         i = i + #number
      elseif name then
         tokens[#tokens + 1] = { kind = "name", value = name:lower() }
         i = i + #name
      else
         local char = rest:sub(1, 1)
         if not ("+-*/%^()"):find(char, 1, true) then
            fail("unexpected character '"..char.."'")
         end
         tokens[#tokens + 1] = { kind = char }
         i = i + 1
      end
   end

   return tokens
end

--- @param src string Expression as the player typed it
--- @param constants table Names the expression may read, `ans` among them
--- @return number
function Expr.eval(src, constants)
   local tokens = tokenize(src)
   local pos = 1

   local function peek()
      return tokens[pos]
   end

   local function take(kind)
      local token = tokens[pos]
      if token and token.kind == kind then
         pos = pos + 1
         return token
      end
      return nil
   end

   local parse_expression
   local parse_unary

   local function parse_primary()
      local token = peek()
      if not token then
         fail("the expression ends too early")
      end

      if take("(") then
         local value = parse_expression()
         if not take(")") then
            fail("missing ')'")
         end
         return value
      end

      if token.kind == "number" then
         pos = pos + 1
         return token.value
      end

      if token.kind == "name" then
         pos = pos + 1

         local func = functions[token.value]
         if func then
            if not take("(") then
               fail("'"..token.value.."' wants its argument in brackets")
            end
            local argument = parse_expression()
            if not take(")") then
               fail("missing ')' after "..token.value)
            end
            return func(argument)
         end

         local constant = constants[token.value]
         if constant then
            return constant
         end

         fail("unknown name '"..token.value.."'")
      end

      fail("'"..token.kind.."' cannot start a value")
   end

   local function parse_power()
      local base = parse_primary()
      if take("^") then
         return base ^ parse_unary()
      end
      return base
   end

   parse_unary = function()
      if take("-") then
         return -parse_unary()
      end
      if take("+") then
         return parse_unary()
      end
      return parse_power()
   end

   local function parse_product()
      local value = parse_unary()
      while true do
         if take("*") then
            value = value * parse_unary()
         elseif take("/") then
            local divisor = parse_unary()
            if divisor == 0 then
               fail("division by zero")
            end
            value = value / divisor
         elseif take("%") then
            local divisor = parse_unary()
            if divisor == 0 then
               fail("division by zero")
            end
            value = value % divisor
         else
            return value
         end
      end
   end

   parse_expression = function()
      local value = parse_product()
      while true do
         if take("+") then
            value = value + parse_product()
         elseif take("-") then
            value = value - parse_product()
         else
            return value
         end
      end
   end

   if #tokens == 0 then
      fail("nothing to calculate")
   end

   local value = parse_expression()
   if pos <= #tokens then
      fail("'"..tostring(tokens[pos].kind).."' is left over")
   end
   if value ~= value then
      fail("the answer is not a number")
   end
   if value == math.huge or value == -math.huge then
      fail("the answer does not fit in a number")
   end

   return value
end

--- @param value number
--- @return string
function Expr.format(value)
   if value == math.floor(value) and math.abs(value) < 1e15 then
      return string.format("%d", value)
   end

   return string.format("%.10g", value)
end

return Expr
