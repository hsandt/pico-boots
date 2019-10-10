require("engine/core/class")

--[[
Abstract base class for managers

Static attributes
  type       string   type name used to store and access managers

Instance external references
  app        gameapp  game app instance
                      Inject it in your derived
                        app:instantiate_gamestates.

Instance state
  active     bool     active state
                      When true, this manager is updated
                        and rendered in the game loop.

Methods
  start      ()       start callback
  update     ()       update callback
  render     ()       render callback
--]]

local manager = new_class()

manager.type = ':undefined'

-- make sure to call base constructor in subclass constructor:
--   manager._init(self)
function manager:_init(app)
  self.app = app
  self.active = true
end

function manager:start()
end

function manager:update()
end

function manager:render()
end

return manager
