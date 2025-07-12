#!/usr/bin/env lua

--- QR Image Generation Tests
--- Comprehensive testing of qrimage.lua functionality

local framework = _G.test_framework
local assert = framework.assert

-- Load the QR image module
local qrimage = dofile("qrimage.lua")

-- Test helper functions
local function cleanup_test_files()
    local test_files = {
        "test_output.ppm",
        "test_output.png",
        "test_matrix.ppm",
        "test_error.ppm",
        "test_sizes.ppm",
        "test_border.ppm",
        "invalid_test.xyz",
        "test_temp.tmp.ppm"
    }

    for _, file in ipairs(test_files) do
        framework.delete_file(file)
    end
end

--- Basic Image Generation Tests
framework.suite("Basic Image Generation")
    :setup(function()
        cleanup_test_files()
    end)
    :teardown(function()
        cleanup_test_files()
    end)
    :test("generate simple PPM image", function()
        local success, message = qrimage.save_qr_image("TEST", "test_output.ppm")

        assert.is_true(success, "PPM generation should succeed")
        assert.matches(message, "PPM image saved", "Should confirm PPM creation")
        assert.is_true(framework.file_exists("test_output.ppm"), "PPM file should exist")

        -- Check file has reasonable size (not empty)
        local content = framework.read_file("test_output.ppm")
        assert.not_nil(content, "File should have content")
        assert.is_true(#content > 100, "PPM file should have substantial content")
        assert.matches(content, "P6", "Should be P6 PPM format")
    end)
    :test("generate PNG image (if converter available)", function()
        local success, message = qrimage.save_qr_image("TEST", "test_output.png")

        -- This test is conditional based on system having image converters
        if success then
            assert.matches(message, "Image saved as.*png", "Should confirm PNG creation")
            assert.is_true(framework.file_exists("test_output.png"), "PNG file should exist")
        else
            assert.matches(message, "No suitable image converter", "Should explain conversion failure")
        end
    end)

--- Matrix to Image Tests
framework.suite("Matrix to Image Conversion")
    :setup(function()
        cleanup_test_files()
    end)
    :teardown(function()
        cleanup_test_files()
    end)
    :test("save matrix directly to image", function()
        -- Generate a matrix first
        local qrencode = dofile("qrencode.lua")
        local ok, matrix = qrencode.qrcode("MATRIX_TEST")
        assert.is_true(ok, "Matrix generation should succeed")

        -- Save matrix to image
        local success, _ = qrimage.save_matrix_image(matrix, "test_matrix.ppm")
        assert.is_true(success, "Matrix image save should succeed")
        assert.is_true(framework.file_exists("test_matrix.ppm"), "Matrix image should exist")
    end)
    :test("custom module size and border", function()
        local success, message = qrimage.save_qr_image("SIZE_TEST", "test_sizes.ppm", {
            module_size = 20,
            border = 8
        })

        assert.is_true(success, "Custom size should work")
        assert.is_true(framework.file_exists("test_sizes.ppm"), "Custom size file should exist")

        -- Verify the dimensions in the message
        -- For a simple QR code with 20px modules and 8 border: size varies by content
        -- Just check that large dimensions are reported
        assert.matches(message, "%d+x%d+", "Should report dimensions")
    end)

--- Error Handling Tests
framework.suite("Error Handling")
    :setup(function()
        cleanup_test_files()
    end)
    :teardown(function()
        cleanup_test_files()
    end)
    :test("invalid file extension", function()
        local success, message = qrimage.save_qr_image("TEST", "invalid_test.xyz")

        assert.is_false(success, "Invalid extension should fail")
        assert.matches(message, "Unsupported format", "Should explain format error")
    end)
    :test("no file extension", function()
        local success, message = qrimage.save_qr_image("TEST", "no_extension")

        assert.is_false(success, "Missing extension should fail")
        assert.matches(message, "No file extension", "Should explain extension error")
    end)
    :test("nil matrix input", function()
        local success, message = qrimage.save_matrix_image(nil, "test_error.ppm")

        assert.is_false(success, "Nil matrix should fail")
        assert.matches(message, "No matrix data", "Should explain matrix error")
    end)
    :test("invalid directory path", function()
        local success, message = qrimage.save_qr_image("TEST", "/nonexistent/directory/test.ppm")

        assert.is_false(success, "Invalid path should fail")
        assert.matches(message, "Could not open file", "Should explain file error")
    end)

--- Parameter Validation Tests
framework.suite("Parameter Validation")
    :setup(function()
        cleanup_test_files()
    end)
    :teardown(function()
        cleanup_test_files()
    end)
    :test("default parameters", function()
        local success, _ = qrimage.save_qr_image("DEFAULT", "test_default.ppm")

        assert.is_true(success, "Default parameters should work")
        -- Default should be module_size=10, border=4
        -- For a simple QR code, this should result in predictable dimensions
        assert.is_true(framework.file_exists("test_default.ppm"), "Default file should exist")
        framework.delete_file("test_default.ppm")
    end)
    :test("zero module size handling", function()
        local success, _ = qrimage.save_qr_image("ZERO", "test_zero.ppm", {
            module_size = 0
        })

        -- Should either fail gracefully or use default
        -- The current implementation treats 0 as falsy, so defaults to 10
        assert.is_true(success, "Zero module size should default")
        framework.delete_file("test_zero.ppm")
    end)
    :test("negative border handling", function()
        local success, _ = qrimage.save_qr_image("NEG", "test_neg.ppm", {
            border = -1
        })

        -- Should either fail gracefully or use default
        assert.is_true(success, "Negative border should be handled")
        framework.delete_file("test_neg.ppm")
    end)

--- File Format Tests
framework.suite("File Format Validation")
    :setup(function()
        cleanup_test_files()
    end)
    :teardown(function()
        cleanup_test_files()
    end)
    :test("PPM header validation", function()
        local success, _ = qrimage.save_qr_image("HEADER", "test_header.ppm")
        assert.is_true(success, "PPM generation should succeed")

        local content = framework.read_file("test_header.ppm")
        assert.not_nil(content, "File should exist")

        -- Check PPM header format
        local lines = {}
        for line in content:gmatch("[^\n]+") do
            table.insert(lines, line)
        end

        assert.equal(lines[1], "P6", "Should have correct PPM magic number")
        assert.matches(lines[2], "%d+ %d+", "Should have width height dimensions")
        assert.equal(lines[3], "255", "Should have correct max color value")

        framework.delete_file("test_header.ppm")
    end)
    :test("case insensitive extensions", function()
        local test_cases = {
            {"test_upper.PPM", true},  -- PPM should work
            {"test_mixed.Png", false}, -- PNG depends on converter
            {"test_lower.jpg", false}  -- JPEG depends on converter
        }

        for _, case in ipairs(test_cases) do
            local filename, should_succeed_unconditionally = case[1], case[2]
            local success, _ = qrimage.save_qr_image("CASE", filename)

            if should_succeed_unconditionally then
                assert.is_true(success, "Extension " .. filename .. " should work")
            end
            -- For converter-dependent formats, we just ensure it doesn't crash

            framework.delete_file(filename)
        end
    end)

--- Integration Tests
framework.suite("Integration Tests")
    :setup(function()
        cleanup_test_files()
    end)
    :teardown(function()
        cleanup_test_files()
    end)
    :test("multiple format generation", function()
        local test_data = "INTEGRATION_TEST"
        local formats = {
            {ext = "ppm", should_work = true},
            {ext = "png", should_work = nil},  -- Depends on system
            {ext = "jpg", should_work = nil}   -- Depends on system
        }

        for i, format in ipairs(formats) do
            local filename = string.format("test_multi_%d.%s", i, format.ext)
            local success, _ = qrimage.save_qr_image(test_data, filename)

            if format.should_work == true then
                assert.is_true(success, format.ext .. " should work")
                assert.is_true(framework.file_exists(filename), format.ext .. " file should exist")
            elseif format.should_work == false then
                assert.is_false(success, format.ext .. " should fail")
            end
            -- For nil (system-dependent), we don't assert success/failure

            framework.delete_file(filename)
        end
    end)
    :test("large QR code generation", function()
        -- Generate a larger QR code with more data
        local large_data = string.rep("LARGE_DATA_TEST_", 10)  -- Repeat to make it bigger
        local success, _ = qrimage.save_qr_image(large_data, "test_large.ppm", {
            module_size = 8,
            border = 6
        })

        assert.is_true(success, "Large QR code should generate")
        assert.is_true(framework.file_exists("test_large.ppm"), "Large QR file should exist")

        -- Check file size is reasonable for a large QR code
        local content = framework.read_file("test_large.ppm")
        assert.is_true(#content > 1000, "Large QR code should produce substantial file")

        framework.delete_file("test_large.ppm")
    end)

--- Command Line Interface Tests
framework.suite("CLI Interface")
    :test("main function with valid arguments", function()
        -- Test the main CLI function
        local args = {"CLI_TEST", "test_cli.ppm", "12", "3"}
        local result = qrimage.main(args)

        assert.equal(result, 0, "CLI should return success code")
        assert.is_true(framework.file_exists("test_cli.ppm"), "CLI should create file")

        framework.delete_file("test_cli.ppm")
    end)
    :test("main function with missing arguments", function()
        local result = qrimage.main({})
        assert.equal(result, 1, "CLI should return error code for missing args")
    end)
    :test("main function with invalid parameters", function()
        local args = {"TEST", "test_invalid.ppm", "not_a_number", "also_not_a_number"}
        local result = qrimage.main(args)

        -- Should handle gracefully (tonumber returns nil, falls back to defaults)
        assert.equal(result, 0, "CLI should handle invalid numbers gracefully")

        framework.delete_file("test_invalid.ppm")
    end)

