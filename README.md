[![Build Status](https://travis-ci.org/hsandt/pico-boots.svg?branch=master)](https://travis-ci.org/hsandt/pico-boots)
[![codecov](https://codecov.io/gh/hsandt/pico-boots/branch/master/graph/badge.svg)](https://codecov.io/gh/hsandt/pico-boots)

# pico-boots

This is a gamestate-based framework for [PICO-8](https://www.lexaloffle.com/pico-8.php). It consists of:

* a collection of modules that can be used as a separate library
* a few classes to help you get your game running as part of an FSM

It is under active development as part of projects such as [pico-sonic](https://github.com/hsandt/sonic-pico8) and [Wit Fighter](https://github.com/hsandt/LD45). The [demo project](https://github.com/hsandt/pico-boots-demo) aims at demonstrating the features and API of the framework.

The full build pipeline will only work on UNIX platforms. A few scripts will try to use commands only present on some Linux distributions, and fallback to more simple behavior else. Tested on Linux Ubuntu 18.04.

## Modules

Modules are grouped under the following folders:

| folder 	  | Role						                     |
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

From any of your modules, you can `require` other modules, but always make sure to pass the relative path from the project source root. This is because picotool doesn't recognize equivalent paths written differently, and would include such modules multiple times in the PICO-8 cartridge.

For the rest, code as you would normally with PICO-8. However, if you want to be able to test your code with busted using the test pipeline provided with this framework, you will also need to:

* write everything in "clean lua" (Lua compatible with both standard Lua interpreters and PICO-8)

* replace all your PICO-8 `print()` calls with `api.print()` and add `require("engine/pico8/api")` at the top of any of your main entry file for it to work in PICO-8

### Data

Create a new PICO-8 cartridge and save it (e.g. as `data.p8`). It will contain no code, only data.

Create your pictures and audio in the cartridge within PICO-8 and save it, or import them from external files (`import .png` command, copy-paste `__gfx__` section, etc.).

You will be able to build your game by merging your code and your data.

### Example

See the [repository for sample game pico-boots demo](https://github.com/hsandt/pico-boots-demo) for a full example.

## Build your game

The engine cannot be built by itself because PICO-8 works with complete cartridges not separate libraries.

Instead, you must first write your game, then build the full PICO-8 cartridge at once using the build pipeline. To build your game:

* `cd path/to/your/project`
* `path/to/pico-boots/scripts/build_cartridge.sh path/to/game/src/main.lua -o build/game.p8 -d path/to/game/data.p8 -m path/to/game/metadata.p8 -a author_name -t game_title`

We recommend you to make your own `build_game.sh` file that uses `build_cartridge.sh` with the right arguments. You'll find [an example](https://github.com/hsandt/pico-boots-demo/blob/master/build_game.sh) in the pico-boots demo repository.

### Supported platforms

The build pipeline relies on Bash and Python scripts and have been tested on Linux Ubuntu. Other Linux distributions and UNIX platforms should be able to run most scripts, providing the right tools are installed. However, scripts using more specific commands such as `gnome-terminal` and `xdotool` would need to be adapted to the development platform. Development environments for Windows such as MinGW and Cygwin have not been tested.

Feel free to open an issue for any script lacking compatibility across UNIX platforms.

The test pipeline consists in testing the Lua sources directly with a Lua unit test framework (see *Test dependencies*), therefore should be cross-platform.

The built PICO-8 cartridge itself can be played on all platforms supported by PICO-8.

### Build dependencies

#### npm

In order to install luamin (a Lua minifier), you'll need [npm](https://www.npmjs.com/get-npm). `scripts/npm/node_modules/package.json` is already setup to install the required tools, you just need to run `setup.sh`, or alternatively:

* `cd scripts/npm`
* `npm update`

It will install `luamin` (along with `luaparse`) to be used in `minify.py`.

Note: I use my own [develop branch](https://github.com/hsandt/luamin/tree/develop) of [luamin](https://github.com/mathiasbynens/luamin). It contains a non-TTY fix merged from [themadsens's branch](https://github.com/themadsens/luamin), and I have added a feature to preserve newlines and make it easier to debug the minified cartridge. Note that the official luamin can also be used, but will not work in non-TTY environment.

#### Python 3.6

Prebuild and postbuild scripts are written in Python 3 and use 3.6 features such as formatted strings.

#### picotool

A build pipeline for PICO-8 ([GitHub](https://github.com/dansanderson/picotool)).

You must add `p8tool` to your `PATH`.

## Test

In pico-boots, we distinguish unit tests *utests* and integration tests *itests*.

### Unit tests

Unit tests are dedicated to testing a specific module, and should be independent from other modules' implementations, except when it comes to handle simple structures like `vector`. Unit tests are run in pure Lua, using the unit test framework `busted`. To cut external dependencies, they heavily rely on the stubbing and mocking mechanics provided by `busted`.

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

#### Conventions

Integration tests should be placed under in a single `itests` folder somewhere in your game project. This is to allow itest discovery when running itests, both headless and in PICO-8. Files are searched recursively, so it's possible to sort them under subdirectories. To customise this folder path, see *Build your itest cartridge* below.

Currently, the pico-boots engine has not integration test at all since it's mostly made of separate components. To run integration tests, pico-boots would need a sample `gameapp`, which is basically already the role of pico-boots-demo. In that sense, pico-boots-demo is the project that ensures that pico-boots' features work inside an actual game loop.

You will also need a main source to run the itests in PICO-8, `itest_main.lua`. See [`itest_main.lua` from pico-boots demo](https://github.com/hsandt/pico-boots-demo/blob/master/src/itest_main.lua) for a template. You just need to replace the `demo_app` with your own gameapp subclass to make it work with your game.

If you add any particular setup to `main.lua`, such as registering a new manager to the app, you should do the same in your `itest_main.lua`.

To run the itests headlessly with busted, you should make a unit test file `/home/wing/Projects/PICO-8/ld45/src/tests/headless_itests_utest.lua`. See [`headless_itests_utest.lua` from pico-boots demo](https://github.com/hsandt/pico-boots-demo/blob/master/src/tests/headless_itests_utest.lua) for a template. It will also collect all the itests in the `itests` folder. You can customise this path (in sync with `itest_main.lua`) by changing the 2nd argument passed to `require_all_scripts_in`.

Just like `itest_main.lua`, if you add any particular setup to `main.lua`, you should do the same in your `headless_itests_utest.lua`.

#### Build your itest cartridge

If you follow the conventions above, you should be able to build a cartridge that runs your integration tests with:

* `cd path/to/your/project`
* `path/to/pico-boots/scripts/build_cartridge.sh path/to/game/src/itest_main.lua itests -o build/itest_all.p8 -d path/to/game/data.p8 -m path/to/game/metadata.p8 -a author_name -t game_title_itest_all`

Similarly to `build_game.sh`, we recommend you to make your own `build_itest.sh` file that uses `build_cartridge.sh` with the right arguments. You'll find [an example](https://github.com/hsandt/pico-boots-demo/blob/master/build_itest.sh) in the pico-boots demo repository. You can customise which folder contains your itests by changing the 2nd argument passed to `build_cartridge.sh`.

### Supported platforms

Unit tests are run directly in Lua, making them cross-platform.

### Test dependencies

#### Lua 5.3

Tests run under Lua 5.3, although Lua 5.2 should also have the needed features (in particular the bit32 module).

#### busted

A Lua unit test framework ([GitHub](https://github.com/Olivine-Labs/busted))

`busted` must be in your path.

#### luacov

A Lua coverage analyzer ([homepage](https://keplerproject.github.io/luacov/))

`luacov` must be in your path.

### Run unit tests

To run all the unit tests of the framework:

* `cd path/to/pico-boots`
* `./test.sh`

To run unit tests for a specific folder inside `src/engine`:

* `./test.sh [folder]`

To run unit tests flagged `#solo` only:

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

[PICO8-WTK](https://github.com/Saffith/PICO8-WTK) has been integrated as a submodule. I use my own fork with a special branch [cleam\n-lua](https://github.com/hsandt/PICO8-WTK/tree/clean-lua), itself derived from the branch [p8tool](https://github.com/hsandt/PICO8-WTK/tree/p8tool).

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
