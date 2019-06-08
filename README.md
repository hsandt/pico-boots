# pico-boots

This is a gamestate-based framework for [PICO-8](https://www.lexaloffle.com/pico-8.php). It consists of:

* a collection of modules that can be used as a separate library
* a few classes to help you get your game running as part of an FSM

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

Create an entry source file `main.lua` in your project source root, and add supporting modules in the same folder or in subfolders.

From any of your modules, you can `require` other modules, but always make sure to pass the relative path from the project source root. This is because picotool doesn't recognize equivalent paths written differently, and would include such modules multiple times in the PICO-8 cartridge.

For the rest, code as you would normally with PICO-8. However, if you want to be able to test your code with busted using the test pipeline provided with this framework, you will also need to:

* write everything in "clean lua" (Lua compatible with both standard Lua interpreters and PICO-8)

* replace all your PICO-8 `print()` calls with `api.print()` and `require("engine/pico8/api")` at the top of any of your main entry file for it to work in PICO-8

See the [repository for sample game pico-boots demo](https://github.com/hsandt/pico-boots-demo) for a full example.

## Build your game

The engine cannot be built by itself because PICO-8 works with complete cartridges not separate libraries.

Instead, you must first write your game, then build the full PICO-8 cartridge at once using the build pipeline. To build your game:

* `cd path/to/your/project`
* `path/to/pico-boots/scripts/build.sh path/to/game/src/main.lua -o build/game.p8 -d path/to/game/data.p8 -m path/to/game/metadata.p8 -a author_name -t game_title`

## Test

All your tests must be named following the convention: `{test_module_basename}_utest.lua`. This is important for test discovery using `scripts/test_scripts.sh`.

Ex: module `helper.lua` must have test `helper_utest.lua`.

In addition, they should all start by requiring `bustedhelper`:

    require("engine/test/bustedhelper")

This is important to benefit from the PICO-8 bridging API `pico8api.lua` (PICO-8-specific functions, including `api.print`) as well as a few other helpers.

There is no enforcement on test location, although we recommend to have tests in the same folder at their tested counterparts, as done in pico-boots and pico-boots demo.

## Supported platforms

Unit tests are run directly in Lua, making them cross-platform.

### Test dependencies

#### Lua 5.3

Tests run under Lua 5.3, although Lua 5.2 should also have the needed features (in particular the bit32 module).

#### busted

A Lua unit test framework ([GitHub](https://github.com/Olivine-Labs/busted))

`busted` must be in your path.

### Run unit tests

To run all the unit tests of the framework:

* `cd path/to/pico-boots`
* `./test.sh`

To run unit tests you wrote for your game, you can also use the test script:

* `cd path/to/your/project`
* `path/to/pico-boots/scripts/test.sh path/to/game/src -l path/to/game/src`
