#!/usr/bin/env lua

--- Test Runner
--- Executes all tests and provides unified reporting

-- Load and run all test files
local framework = dofile("tests/framework.lua")

-- Make framework available globally for test files
_G.test_framework = framework

-- Load individual test suites  
dofile("tests/test_core.lua")
dofile("tests/test_image.lua")

-- Run all tests and exit with appropriate code
local success = framework.run()
os.exit(success and 0 or 1)