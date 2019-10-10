require("engine/core/class")

--[[
Abstract base class for gamestates

Derive your class from it, define type and implement
  callbacks to make your own gamestate for the flow.

Static attributes
  type       string   type name used for transition queries

Instance external references
  app        gameapp  game app instance
                        Inject it in your derived
                        app:instantiate_gamestates.

Methods
  on_enter   ()       enter callback
  on_exit    ()       exit callback
  update     ()       update callback
  render     ()       render callback
--]]

local gamestate = new_class()

gamestate.type = ':undefined'

-- make sure to call base constructor in subclass constructor:
--   gamestate._init(self, app)
function gamestate:_init(app)
  self.app = app
end

function gamestate:on_enter()
end

function gamestate:on_exit()
end

function gamestate:update()
end

function gamestate:render()
end

return gamestate
