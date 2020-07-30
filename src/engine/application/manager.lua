require("engine/common")

--[[
Abstract base class for managers

Static attributes
  type              string   type name used to store and access managers. default: ':undefined'
  initially_active  bool     initial value of `active` attribute. default: true

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
manager.initially_active = true

function manager:_init()
  self.app = nil
  self.active = self.initially_active
end

function manager:start()
end

function manager:update()
end

function manager:render()
end

return manager
