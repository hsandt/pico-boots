import unittest
from . import patch_pico8_js

import logging
from os import path
import shutil
import tempfile


class TestPatchString(unittest.TestCase):

    def test_get_wasm_funcs_string_patched_with_4x_token(self):
        test_wasm = """// EMSCRIPTEN_START_FUNCS
        o=dh(n)|0;if((o|0)>8192){sg(47660,6);c[i>>2]=o}

// EMSCRIPTEN_END_FUNCS
"""

        expected_patched_wasm = """// EMSCRIPTEN_START_FUNCS
        o=dh(n)|0;if((o|0)>32768){sg(47660,6);c[i>>2]=o}

// EMSCRIPTEN_END_FUNCS
"""

        self.assertEqual(patch_pico8_js.get_wasm_funcs_string_patched_with_4x_token(test_wasm),
                         expected_patched_wasm)

    def test_get_wasm_funcs_string_patched_with_fast_load(self):
        test_wasm = """// EMSCRIPTEN_START_FUNCS
        {rm(2928608,b)|0;g=30-(c[732417]|0)|0;h=(g|0)<30?g:30;c[732416]=(h|0)>0?h:0;c[732417]=28}

// EMSCRIPTEN_END_FUNCS
"""

        expected_patched_wasm = """// EMSCRIPTEN_START_FUNCS
        {rm(2928608,b)|0}

// EMSCRIPTEN_END_FUNCS
"""

        self.assertEqual(patch_pico8_js.get_wasm_funcs_string_patched_with_fast_load(test_wasm),
                         expected_patched_wasm)

    # TODO
    def test_get_wasm_funcs_string_patched_with_fast_load(self):
        test_wasm = """// EMSCRIPTEN_START_FUNCS

// EMSCRIPTEN_END_FUNCS
"""

        expected_patched_wasm = """// EMSCRIPTEN_START_FUNCS

// EMSCRIPTEN_END_FUNCS
"""

        self.assertEqual(patch_pico8_js.get_wasm_funcs_string_patched_with_fast_load(test_wasm),
                         expected_patched_wasm)


class TestPatchFile(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_preprocess_dir_in_debug(self):
        test_wasm = """// EMSCRIPTEN_START_FUNCS
        o=dh(n)|0;if((o|0)>8192){sg(47660,6);c[i>>2]=o}
        {rm(2928608,b)|0;g=30-(c[732417]|0)|0;h=(g|0)<30?g:30;c[732416]=(h|0)>0?h:0;c[732417]=28}

// EMSCRIPTEN_END_FUNCS
"""

        expected_patched_wasm = """// EMSCRIPTEN_START_FUNCS
        o=dh(n)|0;if((o|0)>32768){sg(47660,6);c[i>>2]=o}
        {rm(2928608,b)|0}

// EMSCRIPTEN_END_FUNCS
"""

        test_input_filepath = path.join(self.test_dir, 'test.js')
        test_output_filepath = path.join(self.test_dir, 'test_patched.js')

        with open(test_input_filepath, 'w') as f:
            f.write(test_wasm)

        patch_pico8_js.patch_js_file(test_input_filepath, test_output_filepath)

        with open(test_output_filepath, 'r') as f:
            self.assertEqual(f.read(), expected_patched_wasm)


if __name__ == '__main__':
    logging.basicConfig(level=logging.CRITICAL)
    unittest.main()
