import unittest
from . import adapt_for_png

import logging
from os import path
import shutil
import tempfile


class TestAdaptForPNG(unittest.TestCase):

    def test_get_p8_code_with_p8_png_ext_constant_assignment(self):
        test_p8 = """cartridge_ext=".p8"
"""

        expected_adapted_p8 = """cartridge_ext=".p8.png"
"""

        self.assertEqual(adapt_for_png.get_p8_code_with_p8_png_ext(test_p8),
                         expected_adapted_p8)

    def test_get_p8_code_with_p8_png_ext_concatenated_assignment_single_quotes(self):
        test_p8 = """filepath=filebase..'.p8'
"""

        expected_adapted_p8 = """filepath=filebase..'.p8.png'
"""

        self.assertEqual(adapt_for_png.get_p8_code_with_p8_png_ext(test_p8),
                         expected_adapted_p8)

    def test_get_p8_code_with_p8_png_ext_concatenated_assignment_double_quotes(self):
        test_p8 = """filepath=filebase..".p8"
"""

        expected_adapted_p8 = """filepath=filebase..".p8.png"
"""

        self.assertEqual(adapt_for_png.get_p8_code_with_p8_png_ext(test_p8),
                         expected_adapted_p8)

    def test_get_p8_code_with_p8_png_ext_direct_usage_single_quotes(self):
        test_p8 = """reload(0, 0, 'data.p8')
"""

        expected_adapted_p8 = """reload(0, 0, 'data.p8.png')
"""

        self.assertEqual(adapt_for_png.get_p8_code_with_p8_png_ext(test_p8),
                 expected_adapted_p8)

    def test_get_p8_code_with_p8_png_ext_direct_usage_double_quotes(self):
        test_p8 = """reload(0, 0, "data.p8")
"""

        expected_adapted_p8 = """reload(0, 0, "data.p8.png")
"""

        self.assertEqual(adapt_for_png.get_p8_code_with_p8_png_ext(test_p8),
                         expected_adapted_p8)

    def test_get_p8_code_with_p8_png_ext_concatenation_single_quotes(self):
        test_p8 = """reload(0, 0, data_name..'.p8')
"""

        expected_adapted_p8 = """reload(0, 0, data_name..'.p8.png')
"""

        self.assertEqual(adapt_for_png.get_p8_code_with_p8_png_ext(test_p8),
                         expected_adapted_p8)

    def test_get_p8_code_with_p8_png_ext_concatenation_double_quotes(self):
        test_p8 = """reload(0, 0, data_name..".p8")
"""

        expected_adapted_p8 = """reload(0, 0, data_name..".p8.png")
"""

        self.assertEqual(adapt_for_png.get_p8_code_with_p8_png_ext(test_p8),
                         expected_adapted_p8)


class TestPatchFile(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_adapt_p8_for_png(self):
        test_p8 = """cartridge_ext=".p8"
"""

        test_p8_minified = """a=".p8"
"""

        expected_adapted_p8 = """cartridge_ext=".p8.png"
"""

        expected_adapted_p8_minified = """a=".p8.png"
"""

        test_input_filepath = path.join(self.test_dir, 'test.p8')
        test_input_filepath_minified = path.join(self.test_dir, 'test_min.p8')
        test_output_filepath = path.join(self.test_dir, 'p8_for_png', 'test.p8')
        test_output_filepath_minified = path.join(self.test_dir, 'p8_for_png', 'test_min.p8')

        with open(test_input_filepath, 'w') as f:
            f.write(test_p8)

        with open(test_input_filepath_minified, 'w') as f:
            f.write(test_p8_minified)

        adapt_for_png.adapt_p8_for_png([test_input_filepath, test_input_filepath_minified])

        with open(test_output_filepath, 'r') as f:
            self.assertEqual(f.read(), expected_adapted_p8)

        with open(test_output_filepath_minified, 'r') as f:
            self.assertEqual(f.read(), expected_adapted_p8_minified)


if __name__ == '__main__':
    logging.basicConfig(level=logging.CRITICAL)
    unittest.main()
