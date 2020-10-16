local itest_manager = require("engine/test/itest_manager")
local itest_run = require("engine/test/itest_run")
local test_states = itest_run.test_states

-- helper functions to find and run all headless itests in a project
-- should only be required by head_itests_utest.lua

-- return sequence of all .lua files found recursively under dir
local function find_all_scripts_in(dir)
  local files = {}
  local p = io.popen('find "'..dir..'" -type f -name *.lua')
  for file in p:lines() do
    add(files, file)
  end
  return files
end

-- require all (itest) scripts from (itest) directory [source_dir]/[relative_dir]
-- this will automatically register any itests to the itest_manager
function require_all_scripts_in(source_dir, itest_relative_dir)
  local extension = '.lua'
  local itest_dir = source_dir..'/'..itest_relative_dir
  local itest_scripts = find_all_scripts_in(itest_dir)
  for itest_script in all(itest_scripts) do
    -- truncate the src path prefix and trim file extension since to avoid duplicate modules with picotool,
    -- we must always require following the same convention, i.e. the path from src directory without .lua
    local require_path = itest_script:sub(source_dir:len() + 1, - (extension:len() + 1))
    -- warning: don't put this script (headless_itest.lua) in the folder [itest_dir] to avoid infinite recursion
    require(require_path)
  end
end

-- return true if environment is set to enable rendering for headless itests
function check_env_should_render()
  -- check env variables
  local enable_render_value = tonumber(os.getenv('ENABLE_RENDER'))
  -- ENABLE_RENDER must be set to a positive value
  -- (safety check to avoid nil/number comparison error if not set)
  return enable_render_value and enable_render_value > 0
end

-- app                                      gameapp     game app to test, used by itest runner
-- should_render                            bool        should we render in the loop?
--                                                      useful even in headless to detect render errors
-- describe, setup, teardown, before_each, after_each, it, assert
--                                          function    functions provided by busted
--                                                      (inaccessible in required module, must be passed)
function create_describe_headless_itests_callback(app, should_render, describe, setup, teardown, before_each, after_each, it, assert)

  describe('headless itest', function ()

    -- define a headless unit test for each registered itest so far
    for i = 1, #itest_manager.itests do

      local itest = itest_manager.itests[i]

      describe(itest.name, function ()

        -- better than teardown as it won't be called if test is filtered out (mute / solo)
        -- do not move this outside of this describe, as it would then still be called when test
        --   is filtered out
        after_each(function ()
          itest_manager:stop_and_reset_game()
        end)

        it('should succeed', function ()
          -- don't init and start in setup, as it would also do it for tests that are
          -- filtered out (as with mute / solo)
          itest_manager:init_game_and_start_by_index(i)

          -- itest_manager:init_game_and_start_by_index(i)
          while itest_manager.itest_run.current_state == test_states.running do
            itest_manager:update()
            if should_render then
              itest_manager:draw()
            end
          end

          local itest_fail_message = nil
          if itest_manager.itest_run.current_message then
            itest_fail_message = "itest '"..itest.name.."' ended with "..itest_manager.itest_run.current_state.." due to:\n"..itest_manager.itest_run.current_message
          end

          assert.are_equal(test_states.success, itest_manager.itest_run.current_state, itest_fail_message)
        end)

      end)

    end

  end)

end
