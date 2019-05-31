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

For the rest, code as you would normally with PICO-8, except you should use "clean lua" (Lua compatible with both standard Lua interpreters and PICO-8) if you want to be able to test your code with busted, using the test pipeline provided with this framework.

See the [sample game repository](https://github.com/hsandt/pico-boots-demo) for a full example.

## Build your game

The engine cannot be built by itself because PICO-8 works with complete cartridges not separate libraries.

Instead, you must first write your game, then build the full PICO-8 cartridge at once using the build pipeline. To build your game:

* `cd path/to/your/project`
* `path/to/pico-boots/scripts/build.sh path/to/game/src/main.lua -o build/game.p8 -d path/to/game/data.p8 -m path/to/game/metadata.p8 -a author_name -t game_title`

## Test

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
