# pico-boots

This is a gamestate-based framework for [PICO-8](https://www.lexaloffle.com/pico-8.php). It consists of:

* a collection of modules that can be used as a separate library
* a few classes to help you get your game running as part of an FSM

The full build pipeline will only work on UNIX platforms. Tested on Linux Ubuntu 18.04.

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

* replace all your PICO-8 `print()` calls with `api.print()` and add `require("engine/pico8/api")` at the top of any of your main entry file for it to work in PICO-8

See the [repository for sample game pico-boots demo](https://github.com/hsandt/pico-boots-demo) for a full example.

## Build your game

The engine cannot be built by itself because PICO-8 works with complete cartridges not separate libraries.

Instead, you must first write your game, then build the full PICO-8 cartridge at once using the build pipeline. To build your game:

* `cd path/to/your/project`
* `path/to/pico-boots/scripts/build_game.sh path/to/game/src/main.lua -o build/game.p8 -d path/to/game/data.p8 -m path/to/game/metadata.p8 -a author_name -t game_title`

We recommend you to make your own `build.sh` file that uses `build_game.sh` with the right arguments. You'll find [an example](https://github.com/hsandt/pico-boots-demo/blob/master/build.sh) in the pico-boots demo repository.

### Supported platforms

The Lua and Python scripts are cross-platform.

The resulting cartridge can be played on all platforms supported by PICO-8.

The build scripts in Bash are for UNIX platforms. They have only been tested on Linux Ubuntu 18.04, however. They don't have commands specific to Ubuntu so they should work on other distro, but they may contain a few specific to Linux, so expect a few scripts to not fully work on OSX.

Feel free to open an issue for any script lacking compatibility across UNIX platforms.

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

Integration tests should be placed under in a single `itests` folder somewhere in your game project. This is to allow itest discovery when running itests, both headless and in PICO-8. Files are searched recursively, so it's possible to sort them under subdirectories.

Currently, the pico-boots engine has not integration test at all since it's mostly made of separate components. To run integration tests, pico-boots would need a sample `gameapp`, which is basically already the role of pico-boots-demo. In that sense, pico-boots-demo is the project that ensures that pico-boots' features work inside an actual game loop.

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
