require("engine/core/class")

--[[
Abstract base class for managers

Static attributes
  type       string   type name used to store and access managers

Instance external references
  app        (gameapp|nil)  game app instance
                            It will be set in gameapp:register_managers.

Instance state
  active     bool           active state
                            When true, this manager is updated
                              and rendered in the game loop.

Methods
  start      ()             start callback
  update     ()             update callback
  render     ()             render callback
--]]

local manager = new_class()

manager.type = ':undefined'

-- Make sure to call base constructor in subclass constructor:
--   manager._init(self)
-- or
--   manager._init(self, false)  -- always start with inactive manager
function manager:_init(active)
  if active == nil then
    active = true
  end

  self.app = nil
  self.active = active
end

function manager:start()
end

function manager:update()
end

function manager:render()
end

return manager
