--- A pocket calculator, and the shortest tour of what a mod can put on the HUD:
--- a toggle in the control bar, a hotkey the player can rebind, and a window built from ui.*.

local Expr = require('expr')

local WindowWidth = 300
local WindowHeight = 430
local HistoryLimit = 40

--- A blank display line still has to take its height, or everything under it jumps.
local Blank = " "

--- Rows of the keypad; "" leaves a hole, the rest are appended to the line as typed.
local Keys = {
   { "C", "(", ")", "<" },
   { "7", "8", "9", "/" },
   { "4", "5", "6", "*" },
   { "1", "2", "3", "-" },
   { "0", ".", "=", "+" },
}

local calculator_mod = {}

local window, input, answer, history_box
local history = {}
local constants = { pi = math.pi, e = math.exp(1), ans = 0 }

local function is_open()
   return window ~= nil and window.visible
end

local function rebuild_history()
   history_box:clear()

   for _, entry in ipairs(history) do
      history_box:add(ui.Button {
         on_click = function()
            input.text = entry.source
            input:focus()
         end,
         ui.Text { text = entry.source.."  =  "..entry.value, font_size = 12, align = "right" },
      })
   end

   history_box:to_start()
end

--- Every keystroke: show what the line is worth so far, and say why when it is worth nothing.
local function preview(text)
   if text:match("^%s*$") then
      answer.text = Blank
      return
   end

   local ok, value = pcall(Expr.eval, text, constants)
   answer.text = ok and Expr.format(value) or value
end

--- Enter keeps the answer: it becomes `ans` and the top line of the history.
local function commit(text)
   local ok, value = pcall(Expr.eval, text, constants)
   if not ok then
      return
   end

   constants.ans = value
   table.insert(history, 1, { source = text:gsub("^%s+", ""):gsub("%s+$", ""), value = Expr.format(value) })
   if #history > HistoryLimit then
      table.remove(history)
   end

   input.text = ""
   answer.text = Blank
   rebuild_history()
end

local function press(key)
   if key == "C" then
      input.text = ""
   elseif key == "<" then
      input.text = input.text:sub(1, -2)
   elseif key == "=" then
      commit(input.text)
      input:focus()
      return
   else
      input.text = input.text..key
   end

   preview(input.text)
   input:focus()
end

local function build_keypad()
   local keypad = ui.Grid { columns = #Keys[1], gap = 4 }

   for _, row in ipairs(Keys) do
      for _, key in ipairs(row) do
         keypad:add(ui.Button {
            on_click = function() press(key) end,
            ui.Text { text = key, font_size = 16, align = "center" },
         })
      end
   end

   return keypad
end

local set_open

local function build()
   input = ui.TextBox {
      hint = "2 + 2 * 2",
      on_changed = preview,
      on_commit = commit,
   }

   answer = ui.Text { text = Blank, font_size = 22, align = "right", wrap = true }
   history_box = ui.Scroll { gap = 2 }

   window = ui.Window {
      title = "Calculator",
      anchor_x = "center",
      anchor_y = "center",
      width = WindowWidth,
      height = WindowHeight,
      ui.VBox {
         gap = 8,
         input,
         answer,
         build_keypad(),
         ui.Border {
            style = "field",
            padding = 4,
            history_box,
         },
      },
   }

   window:show()
end

set_open = function(open)
   if not window then
      if not open then
         return
      end
      build()
   end

   window.visible = open
   window.input = open

   if open then
      input:focus()
   end
end

function calculator_mod.pre_init()
   db:from_table {
      class = "Setting",
      category = "Controls",
      type = "Key",
      name = "CalculatorToggle",
      label = "CalculatorToggle",
      key_binding = "CalculatorToggle",
      default_key = "Ctrl+K",
      key_action = function()
         set_open(not is_open())
      end,
   }
end

function calculator_mod.init()
   hud.add_toggle {
      id = "calculator",
      label = "Calculator",
      glyph = "=",
      is_on = is_open,
      on_click = function()
         set_open(not is_open())
      end,
   }
end

function calculator_mod.post_init()
end

db:mod(calculator_mod)
