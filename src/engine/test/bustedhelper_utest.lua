require("engine/test/bustedhelper")
require("engine/core/math")
require("engine/core/helper")

describe('bustedhelper', function ()

  describe('get_file_line', function ()
    it('should return "file:line" of the get_file_line call by default', function ()
      -- because of the instability of the path string, only check the filename + line
      -- (e.g. "@./src/..." when tested with `busted .`, but "@src/..." when tested with `busted src`)
      local path_parts = strspl(get_file_line(), '/')  -- call on line 11
      -- ex: "@./src/engine/test/bustedhelper_utest.lua:8" => {"@.", ... "bustedhelper_utest.lua:8"}
      local file_line = path_parts[#path_parts]
      assert.are_equal("bustedhelper_utest.lua:11", file_line)  -- line 11
    end)
    it('should return "file:line" of the function calling get_file_line with extra_level 1', function ()
      local function inside()
        local path_parts = strspl(get_file_line(1), '/')
        local file_line = path_parts[#path_parts]
        assert.are_equal("bustedhelper_utest.lua:22", file_line)
      end
      inside()  -- call on line 22
    end)
    it('should return "file:line" of the function calling the function calling get_file_line with extra_level 2', function ()
      local function outside()
        local function inside()
          local path_parts = strspl(get_file_line(2), '/')
          local file_line = path_parts[#path_parts]
          assert.are_equal("bustedhelper_utest.lua:33", file_line)
        end
        inside()
      end
      outside()  -- call on line 33
    end)
  end)

  describe('print_at_line', function ()

    setup(function ()
      stub(_G, "print")  -- native print
      stub(_G, "get_file_line", function (message)
        return "@myfile.lua:89"
      end)
    end)

    teardown(function ()
      print:revert()
      get_file_line:revert()
    end)

    it('should print the current file:line with a message', function ()
      print_at_line("text")
      assert.spy(print).was_called(1)
      assert.spy(print).was_called_with("@myfile.lua:89: text")
    end)

  end)

end)
