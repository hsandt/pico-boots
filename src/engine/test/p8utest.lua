require("engine/test/unittest_helper")

--#if log
local _logging = require("engine/debug/logging")
--#endif

local p8utest = {}

-- unit test framework mimicking some busted features
--  for direct use in pico8 headless
-- busted features supported: "it" as "check" (immediate assert, no collection of test results)


-- unit test manager: registers all utests and runs them
-- utests   [utest]   registered utests
utest_manager = singleton(function (self)
  self.utests = {}
end)
p8utest.utest_manager = utest_manager

function utest_manager:register(utest)
  add(self.utests, utest)
end

function utest_manager:run_all_tests()
  for utest in all(self.utests) do
    -- In general, the assert message will be so long that the previous prints won't be visible
    -- so instead, we print to console so in case of failure, we can check the last test
    -- that started. This way, no need to give a meaningful assert message in each utest,
    -- unless there are some interesting variables to print.
    -- Of course, if we apply the suggestion below and track all tests before summing everything
    -- up (like pico-test, but storing test state internally rather than streaming to output),
    -- we could print all the test results properly to the console.
    log("start pico8 utest: "..utest.name)

    -- For now, callback should test directly with assert which will stop at the first failure,
    -- but it's not convenient to continue running other tests after a failure
    -- to sum-up later, so consider making a custom verify function that
    -- checks a boolean and if false, will print that the test failed later
    utest.callback(utest.name)
  end
end

-- unit test class for pico8
local unit_test = new_class()
p8utest.unit_test = unit_test

-- parameters
-- name        string     test name
-- callback    function   test callback, containing assertions
function unit_test:_init(name, callback)
  self.name = name
  self.callback = callback
end

-- busted-like shortcut functions

function check(name, callback)
  local utest = unit_test(name, callback)
  utest_manager:register(utest)
end

-- helper assert function that will print error message
--  to any registered log (mostly console), and assert
--  with utest name
-- this is useful because assert detailed message is often
--  too long for PICO-8 assert to print, but utest name is not
-- use instead of assert()
function assert_log(utest_name, condition, msg)
  if not condition then
    log(msg)
    assert(false, utest_name)
  end
end

return p8utest
