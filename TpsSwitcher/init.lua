local tps_mod = {}

function tps_mod.pre_init()
end

function tps_mod.init()
end

local function stub_step(num_ticks)
   game.tick_rate = 0
   print(string.format(
      "[TpsSwitcher] WARNING: step %d tick(s) is not implemented yet (no engine API).",
      num_ticks
   ))
end

function tps_mod.post_init()
   local es = EventSystem.get()
   es:sub(defines.events.on_player_spawn, function(_ctx)
      local function tps_button(tps)
         return ui.Button {
            on_click = function()
               game.tick_rate = tps
            end,
            ui.Text(tostring(tps)),
         }
      end

      local win = ui.Window {
         title = "TPS Control",
         anchor_x = "left",
         anchor_y = "top",
         offset_x = 150,
         offset_y = 0,
         ui.Border {
            padding = 12,
            ui.VBox {
               ui.Text "Target TPS",
               ui.HBox {
                  tps_button(20),
                  tps_button(100),
                  tps_button(400),
               },
            },
         },
      }
      win:show()
   end)
end

db:mod(tps_mod)
