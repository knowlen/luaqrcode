#!/usr/bin/env lua

--- Core QR Generation Tests
--- Modernized version of qrtest.lua with comprehensive algorithm validation

local framework = _G.test_framework
local assert = framework.assert

-- Load the QR code library in testing mode
testing = true
local qrcode = dofile("qrencode.lua")

--- Test encoding mode detection
framework.suite("Encoding Mode Detection")
    :test("numeric mode detection", function()
        assert.equal(qrcode.get_mode("0101"), 1, "Pure numeric string")
        assert.equal(qrcode.get_mode("123456789"), 1, "Long numeric string")
    end)
    :test("alphanumeric mode detection", function()
        assert.equal(qrcode.get_mode("HELLO WORLD"), 2, "Alphanumeric string")
        assert.equal(qrcode.get_mode("0-9A-Z $%*./:+-"), 2, "All alphanumeric chars")
    end)
    :test("byte mode detection", function()
        assert.equal(qrcode.get_mode("foär"), 4, "String with non-alphanumeric chars")
        assert.equal(qrcode.get_mode("hello world"), 4, "Lowercase letters")
    end)

--- Test data length encoding
framework.suite("Data Length Encoding")
    :test("length encoding for different modes", function()
        assert.equal(qrcode.get_length("HELLO WORLD", 1, 2), "000001011", "Length encoding")
    end)

--- Test binary conversion utilities
framework.suite("Binary Utilities")
    :test("number to binary conversion", function()
        assert.equal(qrcode.binary(5, 10), "0000000101", "Small number conversion")
        assert.equal(qrcode.binary(779, 11), "01100001011", "Larger number conversion")
    end)
    :test("bitwise XOR operations", function()
        assert.equal(qrcode.bit_xor(141, 43), 166, "XOR operation 1")
        assert.equal(qrcode.bit_xor(179, 0), 179, "XOR with zero")
    end)

--- Test data padding
framework.suite("Data Padding")
    :test("pad data to required length", function()
        local expected = "00101010000000001110110000010001111011000001000111101100000100011110110000010001111011000001000111101100"
        assert.equal(qrcode.add_pad_data(1, 3, "0010101"), expected, "Padding calculation")
    end)

--- Test generator polynomial
framework.suite("Generator Polynomial")
    :test("generator polynomial adjustment", function()
        local tab = qrcode.get_generator_polynominal_adjusted(13, 25)
        assert.equal(tab[1], 0, "First coefficient")
        assert.equal(tab[24], 74, "24th coefficient")
        assert.equal(tab[25], 0, "25th coefficient")

        tab = qrcode.get_generator_polynominal_adjusted(13, 24)
        assert.equal(tab[1], 0, "First coefficient (24 length)")
        assert.equal(tab[23], 74, "23rd coefficient (24 length)")
        assert.equal(tab[24], 0, "24th coefficient (24 length)")
    end)

--- Test bitstring to bytes conversion
framework.suite("Bitstring Conversion")
    :test("convert bitstring to byte array", function()
        local bitstring = "00100000010110110000101101111000110100010111001011011100010011010100001101000000111011000001000111101100"
        local tab = qrcode.convert_bitstring_to_bytes(bitstring)
        assert.equal(tab[1], 32, "First byte conversion")
    end)

--- Test mask functions
framework.suite("Mask Functions")
    :test("pixel mask calculations", function()
        assert.equal(qrcode.get_pixel_with_mask(0, 21, 21, 1), -1, "Mask calculation 1")
        assert.equal(qrcode.get_pixel_with_mask(0, 1, 1, 1), -1, "Mask calculation 2")
    end)

--- Test version/error correction detection
framework.suite("Version and Error Correction")
    :test("automatic version detection", function()
        local str = "HELLO WORLD"
        local a, b, c, d, e = qrcode.get_version_eclevel_mode_bistringlength(str)
        assert.equal(a, 1, "Version detection")
        assert.equal(b, 3, "Error correction level")
        assert.equal(c, "0010", "Mode bitstring")
        assert.equal(d, 2, "Mode number")
        assert.equal(e, "000001011", "Length bitstring")
    end)

--- Test string encoding functions
framework.suite("String Encoding")
    :test("numeric string encoding", function()
        assert.equal(qrcode.encode_string_numeric("01234567"),
                    "000000110001010110011000011", "Numeric encoding")
    end)
    :test("alphanumeric string encoding", function()
        assert.equal(qrcode.encode_string_ascii("HELLO WORLD"),
                    "0110000101101111000110100010111001011011100010011010100001101", "ASCII encoding")
    end)

--- Test remainder calculations
framework.suite("Remainder Calculations")
    :test("remainder lookup table", function()
        assert.equal(qrcode.remainder[40], 0, "Remainder for version 40")
        assert.equal(qrcode.remainder[2], 7, "Remainder for version 2")
    end)

--- Test error correction calculations
framework.suite("Error Correction")
    :test("error correction calculation - test case 1", function()
        local data = {32, 234, 187, 136, 103, 116, 252, 228, 127, 141, 73, 236, 12, 206, 138, 7, 230, 101, 30, 91, 152, 80, 0, 236, 17, 236, 17, 236}
        local ec_expected = {73, 31, 138, 44, 37, 176, 170, 36, 254, 246, 191, 187, 13, 137, 84, 63}
        local ec = qrcode.calculate_error_correction(data, 16)
        for i = 1, #ec_expected do
            assert.equal(ec[i], ec_expected[i], "Error correction byte " .. i)
        end
    end)
    :test("error correction calculation - test case 2", function()
        local data = {32, 234, 187, 136, 103, 116, 252, 228, 127, 141, 73, 236, 12, 206, 138, 7, 230, 101, 30, 91, 152, 80, 0, 236, 17, 236, 17, 236, 17, 236, 17, 236, 17, 236}
        local ec_expected = {66, 146, 126, 122, 79, 146, 2, 105, 180, 35}
        local ec = qrcode.calculate_error_correction(data, 10)
        for i = 1, #ec_expected do
            assert.equal(ec[i], ec_expected[i], "Error correction byte " .. i .. " (case 2)")
        end
    end)
    :test("error correction calculation - test case 3", function()
        local data = {32, 83, 7, 120, 209, 114, 215, 60, 224}
        local ec_expected = {123, 120, 222, 125, 116, 92, 144, 245, 58, 73, 104, 30, 108, 0, 30, 166, 152}
        local ec = qrcode.calculate_error_correction(data, 17)
        for i = 1, #ec_expected do
            assert.equal(ec[i], ec_expected[i], "Error correction byte " .. i .. " (case 3)")
        end
    end)
    :test("error correction calculation - zero data", function()
        local data = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        local ec_expected = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        local ec = qrcode.calculate_error_correction(data, 10)
        for i = 1, #ec_expected do
            assert.equal(ec[i], ec_expected[i], "Zero data error correction " .. i)
        end
    end)

--- Test complete codeword arrangement
framework.suite("Codeword Arrangement")
    :test("arrange codewords and calculate error correction", function()
        -- "HALLO WELT" in alphanumeric, code 5-H
        local data = {32,83,7,120,209,114,215,60,224,236,17,236,17,236,17,236, 17,236, 17,236, 17,236, 17, 236, 17,236, 17,236, 17,236, 17,236, 17,236, 17, 236, 17,236, 17,236, 17,236, 17,236, 17,236}
        local message_expected = {32, 236, 17, 17, 83, 17, 236, 236, 7, 236, 17, 17, 120, 17, 236, 236, 209, 236, 17, 17, 114, 17, 236, 236, 215, 236, 17, 17, 60, 17, 236, 236, 224, 236, 17, 17, 236, 17, 236, 236, 17, 236, 17, 17, 236, 236, 3, 171, 23, 23, 67, 165, 115, 115, 244, 230, 68, 68, 57, 109, 245, 245, 183, 241, 125, 125, 14, 45, 66, 66, 171, 198, 203, 203, 101, 125, 235, 235, 213, 213, 85, 85, 52, 84, 88, 88, 148, 88, 174, 174, 3, 187, 178, 178, 144, 89, 229, 229, 148, 61, 181, 181, 6, 220, 118, 118, 155, 255, 148, 148, 3, 150, 44, 44, 252, 75, 175, 175, 228, 113, 213, 213, 100, 77, 243, 243, 11, 147, 27, 27, 56, 164, 215, 215}

        local tmp = qrcode.arrange_codewords_and_calculate_ec(5, 4, data)
        local message = qrcode.convert_bitstring_to_bytes(tmp)

        for i = 1, #message_expected do
            assert.equal(message[i], message_expected[i], "Arranged codeword " .. i)
        end
    end)

--- Integration test - complete QR generation
framework.suite("Integration Tests")
    :test("complete QR code generation", function()
        local test_string = "HELLO WORLD"
        local ok, matrix = qrcode.qrcode(test_string)

        assert.is_true(ok, "QR generation should succeed")
        assert.type_of(matrix, "table", "Result should be a matrix")
        assert.not_nil(matrix[1], "Matrix should have rows")
        assert.not_nil(matrix[1][1], "Matrix should have data")

        -- Check matrix is square
        local size = #matrix
        assert.is_true(size > 0, "Matrix should have positive size")
        for i = 1, size do
            assert.equal(#matrix[i], size, "Matrix row " .. i .. " should have correct length")
        end
    end)
    :test("QR generation with empty string", function()
        local ok, result = qrcode.qrcode("")
        -- Empty string should still generate a valid QR (it encodes to empty data)
        assert.is_true(ok, "Empty string should generate valid QR")
    end)
    :test("QR generation with various inputs", function()
        local test_cases = {
            "123",
            "TEST",
            "Hello World!",
            "https://example.com",
            "日本"  -- UTF-8 characters
        }

        for _, test_case in ipairs(test_cases) do
            local ok, result = qrcode.qrcode(test_case)
            assert.is_true(ok, "QR generation should succeed for: " .. test_case)
            assert.type_of(result, "table", "Result should be matrix for: " .. test_case)
        end
    end)

