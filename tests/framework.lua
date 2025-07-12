#!/usr/bin/env lua

--- Modern Lua Test Framework
--- Zero-dependency lightweight testing utilities
--- Provides structured testing with clear reporting and error handling

local framework = {}

-- Test statistics
local stats = {
    total = 0,
    passed = 0,
    failed = 0,
    errors = 0,
    current_suite = nil
}

-- Test state
local test_suites = {}

-- Expose test_suites for debugging
framework.test_suites = test_suites

--- Colors for terminal output (if supported)
local colors = {
    reset = '\27[0m',
    red = '\27[31m',
    green = '\27[32m',
    yellow = '\27[33m',
    blue = '\27[34m',
    cyan = '\27[36m',
    white = '\27[37m',
    bold = '\27[1m'
}

-- Disable colors if not in a terminal
if not os.getenv("TERM") then
    for k, _ in pairs(colors) do
        colors[k] = ''
    end
end

--- Create a new test suite
--- @param name string Name of the test suite
--- @return table Test suite object
function framework.suite(name)
    local suite = {
        name = name,
        tests = {},
        setup_fn = nil,
        teardown_fn = nil,
        before_each_fn = nil,
        after_each_fn = nil
    }

    function suite:setup(fn)
        self.setup_fn = fn
        return self
    end

    function suite:teardown(fn)
        self.teardown_fn = fn
        return self
    end

    function suite:before_each(fn)
        self.before_each_fn = fn
        return self
    end

    function suite:after_each(fn)
        self.after_each_fn = fn
        return self
    end

    function suite:test(test_name, test_fn)
        table.insert(self.tests, {
            name = test_name,
            fn = test_fn
        })
        return self
    end

    table.insert(test_suites, suite)
    return suite
end

--- Assertion functions
local assert = {}

function assert.equal(actual, expected, message)
    stats.total = stats.total + 1
    if actual == expected then
        stats.passed = stats.passed + 1
        return true
    else
        stats.failed = stats.failed + 1
        local msg = message or string.format("Expected %q, got %q", tostring(expected), tostring(actual))
        error(msg, 2)
        return false
    end
end

function assert.not_equal(actual, expected, message)
    stats.total = stats.total + 1
    if actual ~= expected then
        stats.passed = stats.passed + 1
        return true
    else
        stats.failed = stats.failed + 1
        local msg = message or string.format("Expected %q to not equal %q", tostring(actual), tostring(expected))
        error(msg, 2)
        return false
    end
end

function assert.is_true(value, message)
    return assert.equal(value, true, message or "Expected true")
end

function assert.is_false(value, message)
    return assert.equal(value, false, message or "Expected false")
end

function assert.is_nil(value, message)
    return assert.equal(value, nil, message or "Expected nil")
end

function assert.not_nil(value, message)
    stats.total = stats.total + 1
    if value ~= nil then
        stats.passed = stats.passed + 1
        return true
    else
        stats.failed = stats.failed + 1
        local msg = message or "Expected non-nil value"
        error(msg, 2)
        return false
    end
end

function assert.type_of(value, expected_type, message)
    return assert.equal(type(value), expected_type,
                       message or string.format("Expected type %q, got %q", expected_type, type(value)))
end

function assert.matches(str, pattern, message)
    stats.total = stats.total + 1
    if string.match(str, pattern) then
        stats.passed = stats.passed + 1
        return true
    else
        stats.failed = stats.failed + 1
        local msg = message or string.format("String %q does not match pattern %q", str, pattern)
        error(msg, 2)
        return false
    end
end

function assert.error(fn, expected_error, message)
    stats.total = stats.total + 1
    local success, err = pcall(fn)
    if success then
        stats.failed = stats.failed + 1
        local msg = message or "Expected function to throw an error"
        error(msg, 2)
        return false
    end

    if expected_error and not string.find(err, expected_error, 1, true) then
        stats.failed = stats.failed + 1
        local msg = message or string.format("Expected error containing %q, got %q", expected_error, err)
        error(msg, 2)
        return false
    end

    stats.passed = stats.passed + 1
    return true
end

function assert.no_error(fn, message)
    stats.total = stats.total + 1
    local success, err = pcall(fn)
    if success then
        stats.passed = stats.passed + 1
        return true
    else
        stats.failed = stats.failed + 1
        local msg = message or string.format("Expected no error, got: %s", err)
        error(msg, 2)
        return false
    end
end

framework.assert = assert

--- File system utilities for testing
function framework.file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

function framework.delete_file(path)
    return os.remove(path)
end

function framework.read_file(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local content = file:read("*all")
    file:close()
    return content
end

--- Run all test suites
function framework.run()
    print(colors.bold .. colors.blue .. "\n🧪 Running Test Suites" .. colors.reset)
    print(string.rep("=", 50))

    for _, suite in ipairs(test_suites) do
        print(colors.cyan .. "\n📦 " .. suite.name .. colors.reset)
        print(string.rep("-", 30))

        stats.current_suite = suite.name

        -- Run suite setup
        local suite_setup_ok = true
        if suite.setup_fn then
            local success, err = pcall(suite.setup_fn)
            if not success then
                print(colors.red .. "❌ Suite setup failed: " .. err .. colors.reset)
                stats.errors = stats.errors + 1
                suite_setup_ok = false
            end
        end

        -- Run each test (only if setup succeeded)
        if suite_setup_ok then
            for _, test in ipairs(suite.tests) do

                -- Run before_each
                local before_each_ok = true
                if suite.before_each_fn then
                    local success, err = pcall(suite.before_each_fn)
                    if not success then
                        print(colors.red .. "❌ " .. test.name .. " (before_each failed: " .. err .. ")" .. colors.reset)
                        stats.errors = stats.errors + 1
                        before_each_ok = false
                    end
                end

                -- Run the actual test (only if before_each succeeded)
                if before_each_ok then
                    local success, err = pcall(test.fn)
                    if success then
                        print(colors.green .. "✅ " .. test.name .. colors.reset)
                    else
                        print(colors.red .. "❌ " .. test.name .. " (" .. err .. ")" .. colors.reset)
                        stats.errors = stats.errors + 1
                    end
                end

                -- Run after_each
                if suite.after_each_fn then
                    local success, err = pcall(suite.after_each_fn)
                    if not success then
                        print(colors.yellow .. "⚠️  after_each failed for " .. test.name .. ": " .. err .. colors.reset)
                    end
                end
            end
        end

        -- Run suite teardown
        if suite.teardown_fn then
            local success, err = pcall(suite.teardown_fn)
            if not success then
                print(colors.yellow .. "⚠️  Suite teardown failed: " .. err .. colors.reset)
            end
        end
    end

    -- Print summary
    print(colors.bold .. "\n📊 Test Summary" .. colors.reset)
    print(string.rep("=", 30))
    print(string.format("Total Assertions: %d", stats.total))
    print(string.format("%s✅ Passed: %d%s", colors.green, stats.passed, colors.reset))
    print(string.format("%s❌ Failed: %d%s", colors.red, stats.failed, colors.reset))
    print(string.format("%s🔥 Errors: %d%s", colors.red, stats.errors, colors.reset))

    local success_rate = stats.total > 0 and (stats.passed / stats.total * 100) or 0
    print(string.format("Success Rate: %.1f%%", success_rate))

    if stats.failed > 0 or stats.errors > 0 then
        print(colors.red .. "\n💥 TESTS FAILED" .. colors.reset)
        return false
    else
        print(colors.green .. "\n🎉 ALL TESTS PASSED" .. colors.reset)
        return true
    end
end

return framework