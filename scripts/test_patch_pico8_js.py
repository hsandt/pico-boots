import unittest
from . import patch_pico8_js

import logging
from os import path
import shutil
import tempfile


class TestPatchString(unittest.TestCase):

    def test_get_wasm_funcs_string_patched_with_4x_token_pico8_0_2_1b(self):
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

    def test_get_wasm_funcs_string_patched_with_4x_token_pico8_0_2_2c(self):
        test_wasm = """// EMSCRIPTEN_START_FUNCS
        o=gh(n)|0;if((o|0)>8192){ug(49924,6);c[i>>2]=o;

// EMSCRIPTEN_END_FUNCS
"""

        expected_patched_wasm = """// EMSCRIPTEN_START_FUNCS
        o=gh(n)|0;if((o|0)>32768){ug(49924,6);c[i>>2]=o;

// EMSCRIPTEN_END_FUNCS
"""

        self.assertEqual(patch_pico8_js.get_wasm_funcs_string_patched_with_4x_token(test_wasm),
                         expected_patched_wasm)

    def test_get_wasm_funcs_string_patched_with_4x_token_hypothetical_incompatible_future_version(self):
        # let's imagine variable o -> p
        test_wasm = """// EMSCRIPTEN_START_FUNCS
        o=gh(n)|0;if((p|0)>8192){ug(49924,6);c[i>>2]=o;

// EMSCRIPTEN_END_FUNCS
"""

        expected_patched_wasm = """// EMSCRIPTEN_START_FUNCS
        o=gh(n)|0;if((p|0)>32768){ug(49924,6);c[i>>2]=o;

// EMSCRIPTEN_END_FUNCS
"""

        self.assertRaises(Exception, patch_pico8_js.get_wasm_funcs_string_patched_with_4x_token, test_wasm)

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


    def test_get_wasm_funcs_string_patched_with_fast_reload_pico8_0_2_1b(self):
        test_wasm = """// EMSCRIPTEN_START_FUNCS
        {rm(2928608,b)|0;g=30-(c[732417]|0)|0;h=(g|0)<30?g:30;c[732416]=(h|0)>0?h:0;c[732417]=28}

// EMSCRIPTEN_END_FUNCS
"""

        expected_patched_wasm = """// EMSCRIPTEN_START_FUNCS
        {rm(2928608,b)|0}

// EMSCRIPTEN_END_FUNCS
"""

        self.assertEqual(patch_pico8_js.get_wasm_funcs_string_patched_with_fast_reload(test_wasm),
                         expected_patched_wasm)


    def test_get_wasm_funcs_string_patched_with_fast_reload_pico8_0_2_2c(self):
        test_wasm = """// EMSCRIPTEN_START_FUNCS
        {Lm(2968664,b)|0;g=30-(c[742431]|0)|0;h=(g|0)<30?g:30;c[742430]=(h|0)>2?h:2;c[742431]=150}
        {...;a[2968664]=0;g=30-(c[742431]|0)|0;h=(g|0)<30?g:30;c[742430]=(h|0)>2?h:2;c[742431]=150;return}

// EMSCRIPTEN_END_FUNCS
"""

        expected_patched_wasm = """// EMSCRIPTEN_START_FUNCS
        {Lm(2968664,b)|0}
        {...;a[2968664]=0;return}

// EMSCRIPTEN_END_FUNCS
"""

        self.assertEqual(patch_pico8_js.get_wasm_funcs_string_patched_with_fast_reload(test_wasm),
                         expected_patched_wasm)

    def test_get_wasm_funcs_string_patched_with_fast_reload_hypothetical_incompatible_future_version(self):
        # let's imagine variable g -> h
        test_wasm = """// EMSCRIPTEN_START_FUNCS
        {Lm(2968664,b)|0;h=30-(c[742431]|0)|0;h=(g|0)<30?g:30;c[742430]=(h|0)>2?h:2;c[742431]=150}
        {...;a[2968664]=0;h=30-(c[742431]|0)|0;h=(g|0)<30?g:30;c[742430]=(h|0)>2?h:2;c[742431]=150;return}

// EMSCRIPTEN_END_FUNCS
"""

        expected_patched_wasm = """// EMSCRIPTEN_START_FUNCS
        {Lm(2968664,b)|0}
        {...;a[2968664]=0;return}

// EMSCRIPTEN_END_FUNCS
"""

        self.assertRaises(Exception, patch_pico8_js.get_wasm_funcs_string_patched_with_fast_reload, test_wasm)


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
