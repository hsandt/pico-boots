-- helper functions to find and run all headless itests in a project
-- should only be required by head_itests_utest.lua
require("engine/test/integrationtest")

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
-- describe, setup, teardown, it, assert    function    functions provided by busted
--                                                      (inaccessible in required module, must be passed)
function create_describe_headless_itests_callback(app, describe, setup, teardown, it, assert)

  describe('headless itest', function ()

    local should_render = false

    setup(function ()
      itest_runner.app = app

      -- check options
      if contains(arg, "--render") then
        print("[headless itest] enabling rendering")
        should_render = true
      end
    end)

    teardown(function ()
      itest_runner:init()
    end)

    -- define a headless unit test for each registered itest so far
    for i = 1, #itest_manager.itests do

      local itest = itest_manager.itests[i]

      it(itest.name..' should succeed', function ()
        -- just require the gamestates you need for this itest
        -- (in practice, any gamestate module required at least once by an itest will be loaded
        -- anyway; this will just redirect untested gamestates to a dummy to avoid useless processing)
        -- commented out for now in pico-boots, which doesn't use gamestate_proxy as pico-sonic did
        -- gamestate_proxy:require_gamestates(itest.active_gamestates)

        itest_manager:init_game_and_start_by_index(i)
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

    end

  end)

end
