[![Build Status](https://travis-ci.org/hsandt/pico-boots.svg?branch=master)](https://travis-ci.org/hsandt/pico-boots)
[![codecov](https://codecov.io/gh/hsandt/pico-boots/branch/master/graph/badge.svg)](https://codecov.io/gh/hsandt/pico-boots)

# pico-boots

This is a gamestate-based framework for [PICO-8](https://www.lexaloffle.com/pico-8.php). It consists of:

* a collection of modules that can be used as a separate library
* a few classes to help you get your game running as part of an FSM

It is under active development as part of projects such as [pico-sonic](https://github.com/hsandt/sonic-pico8) and [Wit Fighter](https://github.com/hsandt/LD45). The [demo project](https://github.com/hsandt/pico-boots-demo) aims at demonstrating the features and API of the framework.

The full build pipeline will only work on UNIX platforms. A few scripts will try to use commands only present on some Linux distributions, and fallback to more simple behavior else. Tested on Linux Ubuntu 18.04.

## Compatibility

PICO-8 version: 0.2.0i ~ 0.2.1b

## Modules

Modules are grouped under the following folders:

| Folder      | Role                                             |
|-------------|--------------------------------------------------|
| application | Control the application flow                     |
| core        | Low-level components and helpers                 |
| data        | Classes to manipulate game data                  |
| debug       | Debugging features                               |
| input       | Input management                                 |
| physics     | 2D collisions                                    |
| pico8       | Bridging API for execution in PICO-8 only		 |
| render      | Generic and sprite rendering                     |
| test        | Assertions and integration test components       |
| ui          | UI overlay and mouse rendering                   |

## Write your game

### Code

Create an entry source file `main.lua` in your project source root, and add supporting modules in the same folder or in subfolders.

IMPORTANT: you should always add `require("engine/common")` (and sometimes `require("engine/common")`, see below) at the top of each of your entry main files. `common.lua` groups `require`s for the most common modules that don't return a table, and without it many modules will not work.

From any of your modules, you can `require` other modules, but always make sure to pass the relative path from the project source root. This is because picotool doesn't recognize equivalent paths written differently, and would include such modules multiple times in the PICO-8 cartridge.

For the rest, code as you would normally with PICO-8. However, if you want to be able to test your code with busted using the test pipeline provided with this framework, you will also need to:

* write everything in "clean lua" (Lua compatible with both standard Lua interpreters and PICO-8)

* replace all your PICO-8 `print()` calls with `api.print()` and add `require("engine/pico8/api")` at the top of any of your main entry file for it to work in PICO-8

### Data

Create a new PICO-8 cartridge and save it (e.g. as `data.p8`). It usually contains no code, only data.

Create your pictures and audio in the cartridge within PICO-8 and save it, or import them from external files (`import .png` command, copy-paste `__gfx__` section, etc.). If you have already started making your graphics and audio in a normal cartridge and want to start using picotool/pico-boots now, simply copy the data sections (e.g. `__gfx__`) of your original cartridge to data.p8.

If you always edit your spritesheet in an external graphics editor and want to auto-import the latest exported version of the spritesheet each time you open `data.p8`, you can fill the `__lua__` section with a single line:

```
import [spritesheet_name].png
```

Make sure that each time you edit your spritesheet in an editor, you export it to `pico-8/carts` (the working directory of PICO-8 on start; check pico-8 path for your platform on [this page](https://pico-8.fandom.com/wiki/Configuration)).

You will be able to build your game by merging your code and your data.

### Example

See the [repository for sample game pico-boots demo](https://github.com/hsandt/pico-boots-demo) for a full example.

## Build your game

The engine cannot be built by itself because PICO-8 works with complete cartridges not separate libraries.

Instead, you must first write your game, then build the full PICO-8 cartridge at once using the build pipeline. To build your game:

* `cd path/to/your/project`
* `path/to/pico-boots/scripts/build_cartridge.sh path/to/game/src/main.lua -o build/game.p8 -d path/to/game/data.p8 -m path/to/game/metadata.p8 -a author_name -t game_title`

We recommend you to make your own `build_game.sh` file that uses `build_cartridge.sh` with the right arguments. You'll find [an example](https://github.com/hsandt/pico-boots-demo/blob/master/build_game.sh) in the pico-boots demo repository.

For more customized builds, you can pass a config with `-c` (used to customize output paths) and defined symbols with `-s` (used to add debug code/strip code in release). See `scripts/build_cartridge.sh` help for the full list of options.

### Pre-build steps

#### Preprocessing

A preprocessing step is done before the actual build in `scripts/preprocess.py`. It strips single-line debug calls if debug symbols are not defined, and applies multi-line symbol preprocessing.

##### Single-line debug call stripping

This functionality has been added to easily strip debug function calls (e.g. `log(...)`) when the corresponding symbol (e.g. `log`) is *not* defined. The script will detect any line starting with `stripped_function(` and ending with `)  -- optional comment`. It is not good enough to know if unclosed brackets remain at the end of the line, so don't play with embedded brackets too much, but it should be enough to strip most common debug function calls.

Currently, the list of stripped functions is hardcoded and cannot be changed by the user. See *Symbols used in the framework* below or refer to `preserved_functions_list_by_symbol` in `scripts/preprocess.py`.

Multi-line debug calls should be surrounded with `#if` conditions (see *Symbol preprocessing* below).

##### Symbol preprocessing

, and is a very light version of what C and C# does. If the user to surround any piece of code with tags:

```lua
--#if symbol
	print("this will only appear if symbol is defined")
--#endif
```

the piece of code will be stripped before being built by picotool, unless `symbol` has been passed as a defined symbol. Multiple symbols can be defined with `build_cartridge.sh -s symbol1,symbol2,etc`.

This is also useful to strip multi-line debug calls, which are ignored by the single-line stripping check. For instance:

```lua
--#if assert
assert(condition, "very long"..
  "line with"..variable)
--#endif
```

will remove the whole assert when the `assert` symbol is not defined.

You are free to define symbols as you wish when using `build_cartridge.sh`, but it is recommended to keep at least `assert` and `log` in your debug build, and not to define any debug symbols in your release build.

##### Symbols used in the framework

In the framework, we are already use the following symbols:

| Symbol        | Preserves functions   | Surrounds                                                      |
|---------------|-----------------------|----------------------------------------------------------------|
| assert        | assert                | Assert helper functions and multi-line assertions              |
| busted        |                       | Helper definitions for busted utests only                      |
| deprecated    |                       | Deprecated items                                               |
| key_access    |                       | Functions handling unminified string keys (see Minification)   |
| log           | log, warn, err        | Logger setup, logging.lua body                                 |
| manager       |                       | gameapp manager system                                         |
| mouse         |                       | Mouse setup, mouse.lua body                                    |
| p8utest       |                       | Helper definitions for PICO-8 utests only (currently unused)   |
| profiler      |                       | Profiler setup, profiler.lua body                              |
| tostring      |                       | class/struct _tostring method definitions, some string helpers |
| tuner         |                       | Tuner setup, codetuner.lua body                                |
| ultrafast     |                       | gameapp:yield_delay_s hack to make coroutine wait shorter      |
| visual_logger |                       | Visual logger setup, visual_logger.lua body                    |

* Note that log should be defined if assert is, as some asserts may rely on the `_tostring` method of some objects for string concatenation.
* Similarly, log should be defined is visual_logger is, as visual_logger implies log and the module doesn't check for `log` symbol by itself.

You will sometimes see `(#symbol)` in comments to indicate that a member or feature is only present if that symbol is defined.

#### Require injection

`scripts/add_require.py` adds `require` statements after any `--[[add_require]]` tag found in a source file.

This is mainly useful for the itest main file (see *Integration tests* section more below).

### Post-build steps

#### Minification

When using `./build_cartridge.sh --minify-level MINIFY_LEVEL` with `MINIFY_LEVEL` equal to 1 or 2, the cartridge code is minified with a custom branch of luamin (see *Build dependencies* below). Currently, it uses upper and lower characters for the minified symbols, which means that if you open the cartridge in PICO-8 for editing, the upper characters will be lowered and this will cause naming conflicts (e.g. `Ab` and `ab` becoming the same variable), as well as keyword conflicts (e.g. `Do` becoming `do`). Therefore, do not try to edit the minified code in PICO-8 (minified code is very hard to read anyway).

For aggressive minification, use `./build_cartridge.sh --minify-level MINIFY_LEVEL 2`. It will minify member names and table keys in general, except when they start with `_` or are defined/accessed dynamically using the `["key"]` syntax. In addition, keys with the same name are always minified to the same shorter name (even if tables holding them are unrelated) to ensure members are accessed consistently.

This means that every time you use a key that will be accessed dynamically with `my_table["key"]` (such as a game resource loaded by name), you should start the key name with `_`, or alternatively be define the table entry using the full syntax `["key"] = value` instead of just `key = value`, to disable minification. Make sure that *all* key accesses are done via string, as any "dot" key access `my_table.key` will still be minified, and probably result in `nil`.

Note that metatable keys like `__call` are always preserved so metable logic can work properly (this is also the original reason why the `_` protection was established).

Ex:

```
local anims = {
  ["idle"] = anim_idle,
  ["hurt"] = anim_hurt,
  _ko      = anim_ko     -- variant, but make sure that you access table with underscore in key too
}
```

You should probably not use the `enum` function in helper.lua if you use aggressive minification, as it will generate enum variants via strings, unless you either start all the name variants with `_`, access your variants with full syntax `my_enum["variant"]`, or use an extra pre/post-processing to replace all occurrences of your enum variants with the corresponding number.

### Supported platforms

The build pipeline relies on Bash and Python scripts and have been tested on Linux Ubuntu. Other Linux distributions and UNIX platforms should be able to run most scripts, providing the right tools are installed. However, scripts using more specific commands such as `gnome-terminal` and `xdotool` would need to be adapted to the development platform. Development environments for Windows such as MinGW and Cygwin have not been tested.

Feel free to open an issue for any script lacking compatibility across UNIX platforms.

The test pipeline consists in testing the Lua sources directly with a Lua unit test framework (see *Test dependencies*), therefore should be cross-platform.

The built PICO-8 cartridge itself can be played on all platforms supported by PICO-8.

### Build dependencies

#### npm

In order to install luamin (a Lua minifier), you'll need [npm](https://www.npmjs.com/get-npm), which is distributed with [Node.js](https://nodejs.org/en/). For a PPA install on Linux, check out the [NodeSource scripts](https://github.com/nodesource/distributions) and pick the script matching your platform and the version you want (LTS should be enough, see Node.js website for more info).

`scripts/npm/node_modules/package.json` is already setup to install the required tools, you just need to run `setup.sh`, or alternatively:

* `cd scripts/npm`
* `npm update`

It will install `luamin` (along with `luaparse`) to be used in `minify.py`.

Note: I use my own [develop branch](https://github.com/hsandt/luamin/tree/develop) of [luamin](https://github.com/mathiasbynens/luamin). It contains a non-TTY fix merged from [themadsens's branch](https://github.com/themadsens/luamin), and I have added a feature to preserve newlines and make it easier to debug the minified cartridge, as well as aggressive minification options in case your cartridge is still too big. Note that the official luamin can also be used, but will not work in non-TTY environment.

#### Python 3.6

Prebuild and postbuild scripts are written in Python 3 and use 3.6 features such as formatted strings.

#### picotool

A build pipeline for PICO-8 ([GitHub](https://github.com/dansanderson/picotool)).

You must add `p8tool` to your `PATH`.

## PICO-8 patching

Patching PICO-8 is an optional step to allow running cartridges that are too big and/or rely a lot on reload(), making the game very slow.

To make this easier, pico-boots offers a number of patches for some OSes and versions of PICO-8. All OSes and versions are not guaranteed to be covered as new PICO-8 updates arrive, as I mostly create the patches to export my own projects at release time.

For now, you can find xdelta patches for Linux and OSX PICO-8 runtime binaries in [pico-boots/scripts/patches](pico-boots/scripts/patches), and a script that automatically creates a patched version of a Linux runtime at [scripts/patch_pico8_runtime.sh](scripts/patch_pico8_runtime.sh).

I am also working on a script to export and immediately patch runtime binaries on [pico-sonic](https://github.com/hsandt/sonic-pico8).

## Test

In pico-boots, we distinguish unit tests *utests* and integration testss *itests*. more

. module, and should be independent from other modules' implementations, except when it comes to handle simple structures like `vector`. Unit tests are run in pure Lua, using the unit test framework `busted`. To cut external dependencies, they heavily rely on the stubbing and mocking mechanics provided by `busted`.

However, the fact that we are using pure Lua means that there are some differences with the same code running under PICO-8. `src/engine/test/pico8api.lua` and `engine/pico8/api.lua` aims to bridge the gap by providing the runtime PICO-8 API, but some lower-level differences remain, such as:

- PICO-8 uses fixed point numbers instead of floating-point numbers. This means some numerical tests will require an extra tolerance to pass in `busted`.

#### Conventions

All the unit tests must be named following the convention: `{test_module_basename}_utest.lua`. This is important for test discovery using `scripts/test_scripts.sh`.

Ex: module `helper.lua` must have test `helper_utest.lua`.

In addition, they should all start by requiring `bustedhelper`:

    require("engine/test/bustedhelper")

This is important to benefit from the PICO-8 bridging API `pico8api.lua` (PICO-8-specific functions, including `api.print`) as well as a few other helpers.

There is no enforcement on test location, although we recommend to have tests in the same folder at their tested counterparts, as done in pico-boots and pico-boots demo.

### Integration tests

Integration tests are simulations. They test how modules work inside an actual game loop, often combining two or more modules together (e.g. menu + input to simulate the user navigating in the menu).

Itests can be run either as unit tests in a headless, pure-Lua environment using `busted`, or directly inside PICO-8. Running headless itests is convenient for quick testing (since the game runs as fast as it can) and automated testing (CI). While running itests in PICO-8 allows the developer to spot issues visually.

Because of the subtle differences noted in the Unit tests section above, results may slightly differ between headless and PICO-8 itests, so be sure to handle those differences in your test code.

#### Itest file

An itest file is a self-contained source that automatically registers an itest definition in the itest manager when `require`d. It requires itself `integrationtest` as well as the modules used for the test, and a big call to `itest_manager:register_itest` in the outer scope (so it is executed immediately on `require`). See [`main_menu_itest.lua` from pico-boots demo](https://github.com/hsandt/pico-boots-demo/src/itests/main_menu_itest.lua) for an example.

#### Conventions

Integration tests should be placed under in a single `itests` folder somewhere in your game project. This is to allow itest discovery when running itests, both headless and in PICO-8. Files are searched recursively, so it's possible to sort them under subdirectories. To customise this folder path, see *Build your itest cartridge* below.

Currently, the pico-boots engine has not integration test at all since it's mostly made of separate components. To run integration tests, pico-boots would need a sample `gameapp`, which is basically already the role of pico-boots-demo. In that sense, pico-boots-demo is the project that ensures that pico-boots' features work inside an actual game loop.

You will also need a main source to run the itests in PICO-8, `itest_main.lua`. See [`itest_main.lua` from pico-boots demo](https://github.com/hsandt/pico-boots-demo/blob/master/src/itest_main.lua) for a template. You just need to replace the `demo_app` with your own gameapp subclass to make it work with your game. The `--[[add_require]]` is important as this is where itest files `require` statements will be injected (see *Require injection* section above).

IMPORTANT: as with `main.lua`, you should make sure to add `require("engine/common")` and `require("common")` at the top of the file (often together with `require("engine/pico8/api")`).

If you add any particular setup to `main.lua`, such as registering a new manager to the app, you should do the same in your `itest_main.lua`.

To run the itests headlessly with busted, you should make a unit test file `src/tests/headless_itests_utest.lua`. See [`headless_itests_utest.lua` from pico-boots demo](https://github.com/hsandt/pico-boots-demo/blob/master/src/tests/headless_itests_utest.lua) for a template. It will also collect all the itests in the `itests` folder. You can customise this path (in sync with `itest_main.lua`) by changing the 2nd argument passed to `require_all_scripts_in`.

Just like `itest_main.lua`, if you add any particular setup to `main.lua`, you should do the same in your `headless_itests_utest.lua`.

#### Build your itest cartridge

If you follow the conventions above, you should be able to build a cartridge that runs your integration tests with:

* `cd path/to/your/project`
* `path/to/pico-boots/scripts/build_cartridge.sh path/to/game/src/itest_main.lua itests -o build/itest_all.p8 -d path/to/game/data.p8 -m path/to/game/metadata.p8 -a author_name -t game_title_itest_all`

Similarly to `build_game.sh`, we recommend you to make your own `build_itest.sh` file that uses `build_cartridge.sh` with the right arguments. You'll find [an example](https://github.com/hsandt/pico-boots-demo/blob/master/build_itest.sh) in the pico-boots demo repository. You can customise which folder contains your itests by changing the 2nd argument passed to `build_cartridge.sh`.

### PICO-8 unit tests

Optionally, you can also create a `utest_main.lua` that will run special unit tests that only make sense in PICO-8 (for instance to test sprite data which are only accessible from the cartridge). A typical content is:

```lua
require("engine/pico8/api")
require("engine/common")
require("common")

local p8utest = require("engine/test/p8utest")
-- tag to add require for pico8 utests files (should be in utests/)
--[[add_require]]

--#if log
local logging = require("engine/debug/logging")
logging.logger:register_stream(logging.console_log_stream)
--#endif

function _init()
  p8utest.utest_manager:run_all_tests()
end
```

You should then define your PICO-8 utests, but remember that unlike busted utests, you don't have access to `describe`, `it` nor the power of luassert. Instead, your p8tests look like this:

```lua
check('sprite 1 should have flag 0 set', function (utest_name)
  assert(fget(1, 0), "sprite 1 has flag 0 unset", utest_name)
end)
```

Then create a build script `build_pico8_utests.sh` that calls `"pico-boots/scripts/build_cartridge.sh" src utest_main.lua utests (more options...)`.

### Supported platforms

Unit tests are run directly in Lua, making them cross-platform.

### Test dependencies

#### Lua 5.3

Tests run under Lua 5.3, although Lua 5.2 should also have the needed features (in particular the bit32 module).

#### busted

A Lua unit test framework ([GitHub](https://github.com/Olivine-Labs/busted))

`busted` must be in your PATH.

#### luacov

A Lua coverage analyzer ([homepage](https://keplerproject.github.io/luacov/))

`luacov` must be in your PATH.

### Run unit tests

To run all the unit tests of the framework:

* `cd path/to/pico-boots`
* `./test.sh`

To run unit tests for a specific folder inside `src/engine`:

* `./test.sh [folder]`

To run unit tests flagged `#solo` in their description only:

* `./test.sh -m solo`

To run all unit tests, including those flagged `#mute`:

* `./test.sh -m all`

Enter `test.sh --help` for more information.

To run unit tests you wrote for your game, you can also use the test script:

* `cd path/to/your/project`
* `path/to/pico-boots/scripts/test_scripts.sh path/to/game/src -l path/to/game/src`

## Development

### Documentation

Most of the documentation lies in comments.

`<fun1, fun2>` means a table that must have methods named `fun1` and `fun2` (defined directly or via a metatable). Since there are no constraints in Lua, the developer must ensure the methods are correctly implemented.

### New project

If you use the scripts of this project to create a new game, in order to use `./edit_data.sh` you need to create a pico8 file at `data/data.p8` first. To do this, open PICO-8, type `save data`, then copy the boilerplate file to `data/data.p8` in your project.

## Runtime third-party libraries

### PICO8-WTK

[PICO8-WTK](https://github.com/Saffith/PICO8-WTK) has been integrated as a submodule. I use my own fork with a special branch [clean-lua](https://github.com/hsandt/PICO8-WTK/tree/clean-lua), itself derived from the branch [p8tool](https://github.com/hsandt/PICO8-WTK/tree/p8tool).

* Branch `p8tool` is dedicated to p8tool integration. It exports variables instead of defining global variables to fit the require pattern.

* Branch `clean-lua` is dedicated to replacing PICO-8 preprocessed expressions like `+=` and `if (...)` with vanilla Lua equivalents. Unfortunately we need this to use external testing libraries running directly on Lua 5.3.

I will soon update WTK to benefit from the new `new` API and features.

## Test third-party libraries

### gamax92/picolove's pico8 API

pico8api.lua contains vanilla lua equivalents or placeholders for PICO-8 functions. They are necessary to test modules from *busted* which runs under vanilla lua. The file is heavily based on gamax92/picolove's [api.lua](https://github.com/gamax92/picolove/blob/master/api.lua) and [main.lua](https://github.com/gamax92/picolove/blob/master/main.lua) (for the `pico8` table), with the following changes:

* Removed console commands (ls, cd, etc.)
* Removed unused functions
* Removed wrapping in api table to import functions globally (except for print)
* Remove implementation for LOVE 2D
* Adapted to Lua 5.3 instead of LuaJIT (uses bit32 module)

Low-level functions have the same behavior as in PICO-8 (add, del, etc.). Rendering functions are mostly stub since our unit tests are headless, although we simulate part of the behavior of PICO-8 by changing the `pico8` table's state (camera, clip, etc.).
