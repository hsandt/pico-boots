require("engine/core/class")

-- abstract base class for gamestates
--
-- derive your class from it, define type and implement
--  callbacks to make your own gamestate for the flow
--
-- attributes
-- type       string  type name used for transition queries
--
-- methods
-- on_enter   ()      enter callback
-- on_exit    ()      exit callback
-- update     ()      update callback
-- render     ()      render callback
local gamestate = new_class()

function gamestate:on_enter()
end

function gamestate:on_exit()
end

function gamestate:update()
end

function gamestate:render()
end

return gamestate
