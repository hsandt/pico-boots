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

## Build

The engine cannot be built by itself because PICO-8 works will complete cartridges not separate libraries.

Instead, follow the instructions on the [sample game repository](https://github.com/hsandt/pico-boots-demo) to learn how to build a simple game, then adapt to your needs.

### Test dependencies

#### Lua 5.3

Tests run under Lua 5.3, although Lua 5.2 should also have the needed features (in particular the bit32 module).

#### busted

A Lua unit test framework ([GitHub](https://github.com/Olivine-Labs/busted))

`busted` must be in your path.

### Run unit tests

To run all the unit tests:

* `cd path/to/pico-boots`
* `./test.sh`
