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
      stub(_G, "get_file_line", function (extra_level)
        return "@myfile.lua:89 from extra level "..tostr(extra_level)
      end)
    end)

    teardown(function ()
      print:revert()
      get_file_line:revert()
    end)

    after_each(function ()
      print:clear()
      get_file_line:clear()
    end)

    it('should print the current file:line with a message, default extra level: 0', function ()
      print_at_line("text")
      assert.spy(print).was_called(1)
      assert.spy(print).was_called_with("@myfile.lua:89 from extra level 1: text")
    end)

    it('should print the current file:line with a message and extra level', function ()
      print_at_line("text", 7)
      assert.spy(print).was_called(1)
      assert.spy(print).was_called_with("@myfile.lua:89 from extra level 8: text")
    end)

  end)

  describe('get_members', function ()
    it('should return module members from their names as multiple values', function ()
      local module = {
        a = 1,
        b = 2,
        [3] = function () end
      }
      assert.are_same({module.a, module.b, module[3]},
        {get_members(module, "a", "b", 3)})
    end)
  end)

end)
