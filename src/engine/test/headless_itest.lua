require("engine/test/integrationtest")

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

        -- better than teardown as it won't be called if test is filtered out (#mute / #solo)
        -- do not move this outside of this describe, as it would then still be called when test
        --   is filtered out
        after_each(function ()
          itest_runner:stop_and_reset_game()
        end)

        it('should succeed', function ()
          -- don't init and start in setup, as it would also do it for tests that are
          -- filtered out (as with #mute / #solo)
          itest_manager:init_game_and_start_by_index(i)

          -- just require the gamestates you need for this itest
          -- (in practice, any gamestate module required at least once by an itest will be loaded
          -- anyway; this will just redirect untested gamestates to a dummy to avoid useless processing)
          -- commented out for now in pico-boots, which doesn't use gamestate_proxy as pico-sonic did
          -- gamestate_proxy:require_gamestates(itest.active_gamestates)

          -- itest_manager:init_game_and_start_by_index(i)
          while itest_runner.current_state == test_states.running do
            itest_runner:update_game_and_test()
            if should_render then
              itest_runner:draw_game_and_test()
            end
          end

          local itest_fail_message = nil
          if itest_runner.current_message then
            itest_fail_message = "itest '"..itest.name.."' ended with "..itest_runner.current_state.." due to:\n"..itest_runner.current_message
          end

          assert.are_equal(test_states.success, itest_runner.current_state, itest_fail_message)

        end)

      end)

    end

  end)

end
