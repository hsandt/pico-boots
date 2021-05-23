import unittest
from . import preprocess

import logging
from os import path
import re
import shutil
import tempfile


class TestGetStrippedFunctions(unittest.TestCase):

    def test_get_stripped_functions_no_symbols(self):
        self.assertEqual(preprocess.get_stripped_functions([]), ['assert', 'log', 'warn', 'err'])

    def test_get_stripped_functions_assert(self):
        self.assertEqual(preprocess.get_stripped_functions(['assert']), ['log', 'warn', 'err'])

    def test_get_stripped_functions_log(self):
        self.assertEqual(preprocess.get_stripped_functions(['log']), ['assert'])

    def test_get_stripped_functions_assert_log(self):
        self.assertEqual(preprocess.get_stripped_functions(['assert', 'log']), [])


class TestGenerateStrippedFunctionCallPattern(unittest.TestCase):

    def test_generate_stripped_function_call_pattern_no_stripped_functions(self):
        self.assertEqual(preprocess.generate_stripped_function_call_pattern([]), None)

    def test_generate_stripped_function_call_pattern_assert(self):
        self.assertEqual(preprocess.generate_stripped_function_call_pattern(['assert']),
                         re.compile('^\\s*(?:assert)\\(.*\\)\\s*(?:--.*)?$'))

    def test_generate_stripped_function_call_pattern_assert_log_warn_err(self):
        self.assertEqual(preprocess.generate_stripped_function_call_pattern(['assert', 'log', 'warn', 'err']),
                         re.compile('^\\s*(?:assert|log|warn|err)\\(.*\\)\\s*(?:--.*)?$'))


class TestMatchStrippedFunctionCall(unittest.TestCase):

    def test_match_stripped_function_call_dont_strip_log_functions(self):
        self.assertFalse(preprocess.match_stripped_function_call('warn("message (inside brackets)")', ['log']))

    def test_match_stripped_function_call_strip_log_functions(self):
        self.assertTrue(preprocess.match_stripped_function_call('warn("message (inside brackets)")', []))


class TestPreprocessLines(unittest.TestCase):

    def test_preprocess_lines_no_directives_preserve(self):
        test_lines = [
            'print ("hi")  \n',
            '\n',
            'if true:  \n',
            '    -- prints hello\n',
            '    print("hello")  -- comment\n',
            '\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), test_lines)

    def test_preprocess_lines_if_log_in_debug(self):
        test_lines = [
            'print("always")\n',
            '\n',
            '--#if debug\n',
            'print("debug")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n',
        ]
        expected_processed_lines = [
            'print("always")\n',
            '\n',
            'print("debug")\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_lines_if_log_in_release(self):
        test_lines = [
            'print("always")\n',
            '\n',
            '--#if debug\n',
            'print("debug")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n',
        ]
        expected_processed_lines = [
            'print("always")\n',
            '\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, []), expected_processed_lines)

    def test_preprocess_lines_2nd_if_refused(self):
        test_lines = [
            '--#if debug\n',
            'print("debug")\n',
            '--#if never\n',
            'print("never")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n',
            '--#endif\n',
        ]
        expected_processed_lines = [
            'print("debug")\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_lines_3rd_if_still_ignore(self):
        test_lines = [
            '--#if debug\n',
            'print("debug")\n',
            '--#if never\n',
            'print("never")\n',
            '--#if never\n',
            'print("never2")\n',
            '--#endif\n',
            'print("never3")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n',
            '--#endif\n',
        ]
        expected_processed_lines = [
            'print("debug")\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_lines_3rd_if_ignored_even_if_true(self):
        test_lines = [
            '--#if debug\n',
            'print("debug")\n',
            '--#if never\n',
            'print("never")\n',
            '--#if debug\n',
            'print("debug2")\n',
            '--#endif\n',
            'print("never3")\n',
            '--#endif\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n',
            '--#endif\n',
        ]
        expected_processed_lines = [
            'print("debug")\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_lines_ifn(self):
        test_lines = [
            'print("always")\n',
            '--#ifn debug\n',
            'print("no log")\n',
            '--#endif\n',
            'print("hello")\n',
        ]
        expected_processed_lines = [
            'print("always")\n',
            'print("hello")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_lines_if_and_ifn(self):
        test_lines = [
            'print("always")\n',
            '--#if debug\n',
            'print("log")\n',
            '--#endif\n',
            '--#ifn debug\n',
            'print("no log")\n',
            '--#endif\n',
            'print("hello")\n',
        ]
        expected_processed_lines = [
            'print("always")\n',
            'print("log")\n',
            'print("hello")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_lines_ifn_inside_if(self):
        test_lines = [
            'print("always")\n',
            '--#if debug\n',
            'print("log")\n',
            '--#ifn debug\n',
            'print("no log")\n',
            '--#endif\n',
            'print("log 2")\n',
            '--#endif\n',
            'print("hello")\n',
        ]
        expected_processed_lines = [
            'print("always")\n',
            'print("log")\n',
            'print("log 2")\n',
            'print("hello")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_lines_if_inside_ifn(self):
        test_lines = [
            'print("always")\n',
            '--#ifn debug\n',
            'print("no log")\n',
            '--#if debug\n',
            'print("log")\n',
            '--#endif\n',
            'print("no log 2")\n',
            '--#endif\n',
            'print("hello")\n',
        ]
        expected_processed_lines = [
            'print("always")\n',
            'print("hello")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_lines_ifn_log_in_release(self):
        test_lines = [
            'print("always")\n',
            '--#ifn debug\n',
            'print("no log")\n',
            '--#endif\n',
            'print("hello")\n',
        ]
        expected_processed_lines = [
            'print("always")\n',
            'print("no log")\n',
            'print("hello")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, []), expected_processed_lines)

    def test_preprocess_if_or_no_condition_met(self):
        test_lines = [
            '--#if ingame || attract_mode\n',
            'print("update level")\n',
            '--#endif\n',
        ]
        expected_processed_lines = [
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, []), expected_processed_lines)

    def test_preprocess_if_or_first_condition_met(self):
        test_lines = [
            '--#if ingame || attract_mode\n',
            'print("update level")\n',
            '--#endif\n',
        ]
        expected_processed_lines = [
            'print("update level")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['ingame']), expected_processed_lines)

    def test_preprocess_if_or_second_condition_met(self):
        test_lines = [
            '--#if ingame || attract_mode\n',
            'print("update level")\n',
            '--#endif\n',
        ]
        expected_processed_lines = [
            'print("update level")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['attract_mode']), expected_processed_lines)

    def test_preprocess_lines_immediate_endif_raises(self):
        test_lines = [
            '--#endif\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n',
        ]
        with self.assertRaises(Exception):
            preprocess.preprocess_lines(test_lines, ['debug'])

    def test_preprocess_lines_endif_inside_non_if_region_type_raises(self):
        test_lines = [
            'print("start")\n',
            '--[[#pico8\n',
            '--#endif\n',
            'real pico8 code\n',
            '--#pico8]]\n',
            'print("end")\n',
        ]
        with self.assertRaises(Exception):
            preprocess.preprocess_lines(test_lines, [])


    def test_preprocess_lines_missing_endif_raises(self):
        test_lines = [
            '--#if debug\n',
            'print("debug")\n',
            '\n',
            'if true:\n',
            '    print("hello")  -- prints hello\n',
        ]
        with self.assertRaises(Exception):
            preprocess.preprocess_lines(test_lines, [])

    def test_preprocess_lines_if_after_blank_acknowledged(self):
        test_lines = [
            '  --#if debug\n',
            '  print("debug")\n',
            '  --#endif\n',
        ]
        expected_processed_lines = [
            '  print("debug")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_lines_if_after_non_blank_preserved(self):
        test_lines = [
            'text before --#if debug\n',
            'print("debug")\n',
            'text before --#endif\n',
        ]
        expected_processed_lines = [
            'text before --#if debug\n',
            'print("debug")\n',
            'text before --#endif\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, []), expected_processed_lines)

    def test_preprocess_else_doesnt_preserve_when_if_is_verified(self):
        test_lines = [
            '--#if debug\n',
            'print("debug")\n',
            '--#else\n',
            'print("release")\n',
            '--#endif\n',
        ]
        expected_processed_lines = [
            'print("debug")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_else_preserves_when_if_is_not_verified(self):
        test_lines = [
            '--#if debug\n',
            'print("debug")\n',
            '--#else\n',
            'print("release")\n',
            '--#endif\n',
        ]
        expected_processed_lines = [
            'print("release")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, []), expected_processed_lines)

    def test_preprocess_else_doesnt_preserve_when_ifn_is_verified(self):
        test_lines = [
            '--#ifn debug\n',
            'print("not debug")\n',
            '--#else\n',
            'print("not release")\n',
            '--#endif\n',
        ]
        expected_processed_lines = [
            'print("not debug")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, []), expected_processed_lines)

    def test_preprocess_else_preserves_when_ifn_is_not_verified(self):
        test_lines = [
            '--#ifn debug\n',
            'print("not debug")\n',
            '--#else\n',
            'print("not release")\n',
            '--#endif\n',
        ]
        expected_processed_lines = [
            'print("not release")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_else_outside_any_block_raises(self):
        test_lines = [
            '--#else\n',
            '--#endif\n',
        ]
        with self.assertRaises(Exception):
            preprocess.preprocess_lines(test_lines, [])

    def test_preprocess_else_inside_non_if_block_raises(self):
        test_lines = [
            '--[[#pico8\n',
            '--#else\n',
            '--#endif\n',
        ]
        with self.assertRaises(Exception):
            preprocess.preprocess_lines(test_lines, [])

    def test_preprocess_lines_pico8_block(self):
        test_lines = [
            'print("start")\n',
            '--[[#pico8 pico8 start\n',
            'real pico8 code\n',
            '--#pico8]] exceptionally ignored\n',
            'print("end")\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'real pico8 code\n',
            'print("end")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, []), expected_processed_lines)

    def test_preprocess_lines_stop_pico8_outside_pico8_block_raises(self):
        test_lines = [
            '--#pico8]]\n',
            'code\n',
        ]
        with self.assertRaises(Exception):
            preprocess.preprocess_lines(test_lines, [])

    def test_preprocess_lines_refused_if_inside_pico8_block(self):
        test_lines = [
            'print("start")\n',
            '--[=[#pico8 pico8 start\n',
            'real pico8 code\n',
            '--#if debug\n',
            'log only\n',
            '--#endif\n',
            '--#pico8]=] exceptionally ignored\n',
            'print("end")\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'real pico8 code\n',
            'print("end")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, []), expected_processed_lines)

    def test_preprocess_lines_accepted_if_inside_pico8_block(self):
        test_lines = [
            'print("start")\n',
            '--[[#pico8 pico8 start\n',
            'real pico8 code\n',
            '--#if debug\n',
            'log only\n',
            '--#endif\n',
            '--#pico8]] exceptionally ignored\n',
            'print("end")\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'real pico8 code\n',
            'log only\n',
            'print("end")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_lines_refused_ifn_inside_pico8_block(self):
        test_lines = [
            'print("start")\n',
            '--[==[#pico8 pico8 start\n',
            'real pico8 code\n',
            '--#ifn debug\n',
            'release only\n',
            '--#endif\n',
            '--#pico8]==] exceptionally ignored\n',
            'print("end")\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'real pico8 code\n',
            'print("end")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_lines_accepted_ifn_inside_pico8_block(self):
        test_lines = [
            'print("start")\n',
            '--[[#pico8 pico8 start\n',
            'real pico8 code\n',
            '--#ifn debug\n',
            'release only\n',
            '--#endif\n',
            '--#pico8]] exceptionally ignored\n',
            'print("end")\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'real pico8 code\n',
            'release only\n',
            'print("end")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, []), expected_processed_lines)

    def test_preprocess_lines_pico8_block_inside_refused_if(self):
        test_lines = [
            'print("start")\n',
            '--#if debug\n',
            '--[=[#pico8 pico8 start\n',
            'log only\n',
            '--#pico8]=] exceptionally ignored\n',
            '--#endif\n',
            'print("end")\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'print("end")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, []), expected_processed_lines)

    def test_preprocess_lines_pico8_block_inside_accepted_if(self):
        test_lines = [
            'print("start")\n',
            '--#if debug\n',
            '--[[#pico8 pico8 start\n',
            'log only\n',
            '--#pico8]] exceptionally ignored\n',
            '--#endif\n',
            'print("end")\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'log only\n',
            'print("end")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_lines_pico8_block_inside_refused_ifn(self):
        test_lines = [
            'print("start")\n',
            '--#ifn debug\n',
            '--[==[#pico8 pico8 start\n',
            'release only\n',
            '--#pico8]==] exceptionally ignored\n',
            '--#endif\n',
            'print("end")\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'print("end")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['debug']), expected_processed_lines)

    def test_preprocess_lines_pico8_block_inside_accepted_ifn(self):
        test_lines = [
            'print("start")\n',
            '--#ifn debug\n',
            '--[[#pico8 pico8 start\n',
            'release only\n',
            '--#pico8]] exceptionally ignored\n',
            '--#endif\n',
            'print("end")\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'release only\n',
            'print("end")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, []), expected_processed_lines)

    def test_preprocess_lines_missing_end_pico8_raises(self):
        test_lines = [
            'print("start")\n',
            '--[[#pico8 pico8 start\n',
            'real pico8 code\n',
            'print("end")\n',
        ]
        with self.assertRaises(Exception):
            preprocess.preprocess_lines(test_lines, [])

    def test_preprocess_lines_pico8_after_blank_acknowledged(self):
        test_lines = [
            'print("start")\n',
            '  --[[#pico8 pico8 start\n',
            'real pico8 code\n',
            '  --#pico8]] exceptionally ignored\n',
            'print("end")\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'real pico8 code\n',
            'print("end")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, []), expected_processed_lines)

    def test_preprocess_lines_pico8_after_non_blank_preserved(self):
        test_lines = [
            'print("start")\n',
            'text  --[[#pico8 pico8 start\n',
            'real pico8 code\n',
            'text  --#pico8]] exceptionally ignored\n',
            'print("end")\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'text  --[[#pico8 pico8 start\n',
            'real pico8 code\n',
            'text  --#pico8]] exceptionally ignored\n',
            'print("end")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, []), expected_processed_lines)

    def test_preprocess_lines_crossing_pico8_then_if(self):
        test_lines = [
            'print("start")\n',
            '--[[#pico8\n',
            '--#if debug\n',
            '--#pico8]]\n',
            '--#endif\n',
            'print("end")\n',
        ]
        with self.assertRaises(Exception):
            preprocess.preprocess_lines(test_lines, ['debug'])

    def test_preprocess_lines_crossing_if_then_pico8(self):
        test_lines = [
            'print("start")\n',
            '--#if debug\n',
            '--[[#pico8\n',
            '--#endif\n',
            '--#pico8]]\n',
            'print("end")\n',
        ]
        with self.assertRaises(Exception):
            preprocess.preprocess_lines(test_lines, ['debug'])

    def test_preprocess_lines_dont_strip_warn(self):
        test_lines = [
            'print("start")\n',
            'warn("keep me")  -- comment\n',
            'print("end")\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'warn("keep me")  -- comment\n',
            'print("end")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['log']), expected_processed_lines)

    def test_preprocess_lines_strip_warn(self):
        test_lines = [
            'print("start")\n',
            'warn("remove me")  -- comment\n',
            'print("end")\n',
        ]
        expected_processed_lines = [
            'print("start")\n',
            'print("end")\n',
        ]
        self.assertEqual(preprocess.preprocess_lines(test_lines, ['']), expected_processed_lines)


class TestPreprocessFile(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_preprocess_file_in_debug(self):
        test_code = """
print("always")

--#if debug
print("debug")
--#endif

if true:
    print("hello")  -- prints hello
"""

        expected_processed_code = """
print("always")

print("debug")

if true:
    print("hello")  -- prints hello
"""

        test_filepath = path.join(self.test_dir, 'test.lua')
        with open(test_filepath, 'w') as f:
            f.write(test_code)
        preprocess.preprocess_file(test_filepath, ['debug'])
        with open(test_filepath, 'r') as f:
            self.assertEqual(f.read(), expected_processed_code)

    def test_preprocess_file_in_release(self):
        test_code = """
print("always")

--#if debug
print("debug")
--#endif

if true:
    print("hello")  -- prints hello
"""

        expected_processed_code = """
print("always")


if true:
    print("hello")  -- prints hello
"""

        test_filepath = path.join(self.test_dir, 'test.lua')
        with open(test_filepath, 'w') as f:
            f.write(test_code)
        preprocess.preprocess_file(test_filepath, [])
        with open(test_filepath, 'r') as f:
            self.assertEqual(f.read(), expected_processed_code)

class TestPreprocessDir(unittest.TestCase):

    def setUp(self):
        # Create a temporary directory
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        # Remove the directory after the test
        shutil.rmtree(self.test_dir)

    def test_preprocess_dir_in_debug(self):
        test_code1 = """
print("file1")

--#if debug
print("debug1")
--#endif

if true:
    print("hello")  -- prints hello
"""

        test_code2 = """
print("file2")

--#if debug
print("debug2")
--#endif

if true:
    print("hello2")  -- prints hello
"""

        expected_processed_code1 = """
print("file1")

print("debug1")

if true:
    print("hello")  -- prints hello
"""

        expected_processed_code2 = """
print("file2")

print("debug2")

if true:
    print("hello2")  -- prints hello
"""

        # files must end with .lua to be processed
        test_filepath1 = path.join(self.test_dir, 'test1.lua')
        with open(test_filepath1, 'w') as f1:
            f1.write(test_code1)
        test_filepath2 = path.join(self.test_dir, 'test2.lua')
        with open(test_filepath2, 'w') as f2:
            f2.write(test_code2)
        preprocess.preprocess_dir(self.test_dir, ['debug'])
        with open(test_filepath1, 'r') as f1:
            self.assertEqual(f1.read(), expected_processed_code1)
        with open(test_filepath2, 'r') as f2:
            self.assertEqual(f2.read(), expected_processed_code2)

    def test_preprocess_dir_in_release(self):
        test_code1 = """
print("file1")

--#if debug
print("debug1")
--#endif

if true:
    print("hello")  -- prints hello
"""

        test_code2 = """
print("file2")

--#if debug
print("debug2")
--#endif

if true:
    print("hello2")  -- prints hello
"""

        expected_processed_code1 = """
print("file1")


if true:
    print("hello")  -- prints hello
"""

        expected_processed_code2 = """
print("file2")


if true:
    print("hello2")  -- prints hello
"""

        # files must end with .lua to be processed
        test_filepath1 = path.join(self.test_dir, 'test1.lua')
        with open(test_filepath1, 'w') as f1:
            f1.write(test_code1)
        test_filepath2 = path.join(self.test_dir, 'test2.lua')
        with open(test_filepath2, 'w') as f2:
            f2.write(test_code2)
        preprocess.preprocess_dir(self.test_dir, [])
        with open(test_filepath1, 'r') as f1:
            self.assertEqual(f1.read(), expected_processed_code1)
        with open(test_filepath2, 'r') as f2:
            self.assertEqual(f2.read(), expected_processed_code2)

if __name__ == '__main__':
    logging.basicConfig(level=logging.CRITICAL)
    unittest.main()
