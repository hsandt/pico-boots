import unittest
from . import unify

import logging
from os import path
import shutil, tempfile


class TestUnify(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    # test_extract_lua has been copied from minify.py, so don't test that again

    def test_unify_lua_minified_lua(self):
        # strings are pretty long, so disable max diff limit
        self.maxDiff = None

        # I extracted this code from a minified cartridge
        lua_code = """a={b={},_c={}}a._c["engine/pico8/api"]=function()c={print=print}end
a._c["engine/common"]=function()if nil then d=0 end
d("engine/application/constants")d("engine/render/color")end
a._c["engine/application/constants"]=function()e=128 end
a._c["engine/render/sprite_data"]=function()local c7=ak()function c7:a7(cr)self.cr=cr end
return c7 end
function d(hQ)local gM=a.b
if gM[hQ]==nil then gM[hQ]=a._c[hQ]()end
if gM[hQ]==nil then gM[hQ]=true end
return gM[hQ]end
d("engine/pico8/api")d("engine/common")
local d4=d("application/myapp_initial_state")
local dj=d4()function _init()dj.df=':initial'dj:dm()end
gd("minified_function_unrelated_to_require_but_with_same_minified_name_end")
function _update60()dj:dr()end
function _draw()dj:dv()end
"""

        expected_unified_lua_code = """c={print=print}if nil then d=0 end
e=128 local c7=ak()function c7:a7(cr)self.cr=cr end


local dj=d4()function _init()dj.df=':initial'dj:dm()end
gd("minified_function_unrelated_to_require_but_with_same_minified_name_end")
function _update60()dj:dr()end
function _draw()dj:dv()end
"""
        lua_filepath = path.join(self.test_dir, 'lua.p8')
        unified_lua_filepath = path.join(self.test_dir, 'unified_lua.p8')
        with open(lua_filepath, 'w') as l:
            l.write(lua_code)

        with open(lua_filepath, 'r') as l, open(unified_lua_filepath, 'w') as cl:
            unify.unify_lua(l, cl)

        with open(unified_lua_filepath, 'r') as cl:
            self.assertEqual(cl.read(), expected_unified_lua_code)

    def test_unify_lua_pico8_lua(self):
        # strings are pretty long, so disable max diff limit
        self.maxDiff = None

        # I extracted this code from a minified cartridge
        lua_code = """package={loaded={},_c={}}
package._c["engine/pico8/api"]=function()

api = { print = print }
end
package._c["engine/common"]=function()

require("engine/application/constants")
require("engine/render/color")

end
package._c["engine/application/constants"]=function()
-- common pico-8 constants

-- screen
screen_width = 128
screen_height = 128

end
package._c["engine/render/sprite_data"]=function()
-- sprite struct
local sprite_data = new_struct()

return sprite_data
end
function require(p)
local l=package.loaded
if (l[p]==nil) l[p]=package._c[p]()
if (l[p]==nil) l[p]=true
return l[p]
end

require("engine/pico8/api")
require("engine/common")

local myapp_initial_state = require("application/myapp_initial_state")

function _init()
end

function _update60()
end

function _draw()
end
"""

        expected_unified_lua_code = """


api = { print = print }






-- common pico-8 constants

-- screen
screen_width = 128
screen_height = 128


-- sprite struct
local sprite_data = new_struct()







function _init()
end

function _update60()
end

function _draw()
end
"""
        lua_filepath = path.join(self.test_dir, 'lua.p8')
        unified_lua_filepath = path.join(self.test_dir, 'unified_lua.p8')
        with open(lua_filepath, 'w') as l:
            l.write(lua_code)

        with open(lua_filepath, 'r') as l, open(unified_lua_filepath, 'w') as cl:
            unify.unify_lua(l, cl)

        with open(unified_lua_filepath, 'r') as cl:
            self.assertEqual(cl.read(), expected_unified_lua_code)


    # inject_lua_in_p8 has been copied from minify.py, so don't test that again


if __name__ == '__main__':
    # we don't want to see errors triggered on purpose during tests,
    # but set this to ERROR if you have an unexpected error to debug
    # (we try to raise as much as possible instead of logging errors, though)
    logging.basicConfig(level=logging.CRITICAL)
    unittest.main()
