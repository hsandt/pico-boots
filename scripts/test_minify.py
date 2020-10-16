import unittest
from . import minify

import logging
from os import path
import shutil, tempfile


class TestMinify(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_extract_lua(self):
        # We actually test p8tool listrawlua
        cartridge_content = """pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
local a = 5
local s = [[
text
]]
__gfx__
eeeeeeeee5eeeeeeeeee
__label__
55222222222222222222
__gff__
00000000000000000000
__map__
45454545eeeeeeeeeeee
__sfx__
010c00002d340293402d
__music__
01 00010203

"""

        # p8tool adds an extra line after each line, but we ignore them in extract_lua already
        expected_extracted_code = """local a = 5
local s = [[
text
]]

"""
        cartridge_filepath = path.join(self.test_dir, 'cartridge.p8')
        extracted_code_filepath = path.join(self.test_dir, 'extracted_code.lua')
        with open(cartridge_filepath, 'w') as l:
            l.write(cartridge_content)

        with open(extracted_code_filepath, 'w') as extracted_code_file:
            minify.extract_lua(cartridge_filepath, extracted_code_file)

        with open(extracted_code_filepath, 'r') as extracted_code_file:
            self.assertEqual(extracted_code_file.read(), expected_extracted_code)

    def test_extract_lua_error(self):
        # We actually test p8tool listrawlua
        cartridge_content = """pico-8 cartridge // http://www.pico-8.com
version 27
__gfx__
eeeeeeeee5eeeeeeeeee
__label__
55222222222222222222
__gff__
00000000000000000000
__map__
45454545eeeeeeeeeeee
__sfx__
010c00002d340293402d
__music__
01 00010203

"""

        cartridge_filepath = path.join(self.test_dir, 'cartridge.p8')
        extracted_code_filepath = path.join(self.test_dir, 'extracted_code.lua')
        with open(cartridge_filepath, 'w') as l:
            l.write(cartridge_content)

        with open(extracted_code_filepath, 'w') as extracted_code_file:
            with self.assertRaises(Exception):
                minify.extract_lua(cartridge_filepath, extracted_code_file)

    def test_clean_lua(self):
        lua_code = """if true then print("ok") end
if true then
  print("ok")
end
if (l[p]==nil) l[p]=package._c[p]()
if (l[p]==nil) l[p]=true

"""

        expected_clean_lua_code = """if true then print("ok") end
if true then
  print("ok")
end
if l[p]==nil then l[p]=package._c[p]() end
if l[p]==nil then l[p]=true end

"""
        lua_filepath = path.join(self.test_dir, 'lua.p8')
        clean_lua_filepath = path.join(self.test_dir, 'clean_lua.p8')
        with open(lua_filepath, 'w') as l:
            l.write(lua_code)

        with open(lua_filepath, 'r') as l, open(clean_lua_filepath, 'w') as cl:
            minify.clean_lua(l, cl)

        with open(clean_lua_filepath, 'r') as cl:
            self.assertEqual(cl.read(), expected_clean_lua_code)

    # in test_minify_lua_*, we are mostly testing luamin itself, with various parameters

    def test_minify_lua_level1(self):
        clean_lua_code = """local my_table =
{
    key1 = 1,
    key2 = "hello",
    _preserved = {},
    ["preserved"] = true
}
if true then
  my_table.key1 = 2
  my_table.key2 = "world"
  my_table._preserved.key1 = 4
  my_table["preserved"] = False
end

"""

        # we use newlines instead of ';' but no aggressive minification
        expected_minified_lua_code = """local a={key1=1,key2="hello",_preserved={},["preserved"]=true}\
if true then a.key1=2
a.key2="world"a._preserved.key1=4
a["preserved"]=False end
"""

        clean_lua_filepath = path.join(self.test_dir, 'clean_lua.p8')
        min_lua_filepath = path.join(self.test_dir, 'lua.p8')
        with open(clean_lua_filepath, 'w') as cl:
            cl.write(clean_lua_code)

        with open(min_lua_filepath, 'w') as ml:
            minify.minify_lua(clean_lua_filepath, ml, minify_level=1)

        with open(min_lua_filepath, 'r') as ml:
            self.assertEqual(ml.read(), expected_minified_lua_code)

    def test_minify_lua_level2(self):
        clean_lua_code = """local my_table =
{
    key1 = 1,
    key2 = "hello",
    _preserved = {},
    ["preserved"] = true
}
if true then
  my_table.key1 = 2
  my_table.key2 = "world"
  my_table._preserved.key1 = 4  -- key with same name should be minified the same
  my_table["preserved"] = False
end

"""

        # we use newlines instead of ';' and minify member names and table key strings
        expected_minified_lua_code = """local a={b=1,c="hello",_preserved={},["preserved"]=true}\
if true then a.b=2
a.c="world"a._preserved.b=4
a["preserved"]=False end
"""

        clean_lua_filepath = path.join(self.test_dir, 'clean_lua.p8')
        min_lua_filepath = path.join(self.test_dir, 'lua.p8')
        with open(clean_lua_filepath, 'w') as cl:
            cl.write(clean_lua_code)

        with open(min_lua_filepath, 'w') as ml:
            minify.minify_lua(clean_lua_filepath, ml, minify_level=2)

        with open(min_lua_filepath, 'r') as ml:
            self.assertEqual(ml.read(), expected_minified_lua_code)

    def test_minify_lua_level3(self):
        clean_lua_code = """local my_table =
{
    key1 = 1,
    key2 = "hello",
    _preserved = {},
    ["preserved"] = true
}
if true then
  my_table.key1 = 2
  my_table.key2 = "world"
  my_table._preserved.key1 = 4  -- key with same name should be minified the same
  my_table["preserved"] = False
end
for k, v in pairs() do
end
global_var = 123
local result = global_var + 1
"""

        # we use newlines instead of ';' and minify member names and table key strings
        expected_minified_lua_code = """local a={b=1,c="hello",_preserved={},["preserved"]=true}\
if true then a.b=2
a.c="world"a._preserved.b=4
a["preserved"]=False end
for d,e in pairs()do end
f=123
local g=f+1
"""

        clean_lua_filepath = path.join(self.test_dir, 'clean_lua.p8')
        min_lua_filepath = path.join(self.test_dir, 'lua.p8')
        with open(clean_lua_filepath, 'w') as cl:
            cl.write(clean_lua_code)

        with open(min_lua_filepath, 'w') as ml:
            minify.minify_lua(clean_lua_filepath, ml, minify_level=3)

        with open(min_lua_filepath, 'r') as ml:
            self.assertEqual(ml.read(), expected_minified_lua_code)

    def test_minify_lua_invalid_source(self):
        invalid_lua_code = """local a = }{"""

        invalid_lua_filepath = path.join(self.test_dir, 'invalid_lua.p8')
        min_lua_filepath = path.join(self.test_dir, 'lua.p8')
        with open(invalid_lua_filepath, 'w') as cl:
            cl.write(invalid_lua_code)

        with open(min_lua_filepath, 'w') as ml:
            with self.assertRaises(Exception):
                minify.minify_lua(invalid_lua_filepath, ml, minify_level=2)

    def test_inject_minified_lua_in_p8(self):
        source_text = """pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
package={loaded={},_c={}}
package._c["module"]=function()
require("another_module")
local long_name = 5
end
__gfx__
eeeeeeeee5eeeeeeeeee
__label__
55222222222222222222
__gff__
00000000000000000000
__map__
45454545eeeeeeeeeeee
__sfx__
010c00002d340293402d
__music__
01 00010203

"""

        min_lua_code = """package={loaded={},_c={}} package._c["module"]=function()require("another_module")local a=5 end"""

        expected_target_text = """pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
package={loaded={},_c={}} package._c["module"]=function()require("another_module")local a=5 end
__gfx__
eeeeeeeee5eeeeeeeeee
__label__
55222222222222222222
__gff__
00000000000000000000
__map__
45454545eeeeeeeeeeee
__sfx__
010c00002d340293402d
__music__
01 00010203

"""

        source_filepath = path.join(self.test_dir, 'source.p8')
        target_filepath = path.join(self.test_dir, 'target.p8')
        min_lua_filepath = path.join(self.test_dir, 'min_lua.lua')
        with open(source_filepath, 'w') as s:
            s.write(source_text)
        with open(min_lua_filepath, 'w') as l:
            l.write(min_lua_code)

        with open(source_filepath, 'r') as s, open(target_filepath, 'w') as t, open(min_lua_filepath, 'r') as l:
            minify.inject_minified_lua_in_p8(s, t, l)

        with open(target_filepath, 'r') as t:
            self.assertEqual(t.read(), expected_target_text)


if __name__ == '__main__':
    # we don't want to see errors triggered on purpose during tests,
    # but set this to ERROR if you have an unexpected error to debug
    # (we try to raise as much as possible instead of logging errors, though)
    logging.basicConfig(level=logging.CRITICAL)
    unittest.main()
