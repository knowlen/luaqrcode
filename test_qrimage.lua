#!/usr/bin/env lua

--- Test script for qrimage.lua
--- Tests both PPM and PNG output

local qrimage = dofile("qrimage.lua")

print("Testing QR Image Generation")
print("=" .. string.rep("=", 30))

-- Test 1: Basic QR code generation (PPM format)
print("\nTest 1: PPM format")
local success, message = qrimage.save_qr_image("Hello World", "test_hello.ppm", {
    module_size = 8,
    border = 4
})

if success then
    print("✓ " .. message)
else
    print("✗ " .. message)
end

-- Test 2: PNG format (requires converter)
print("\nTest 2: PNG format")
success, message = qrimage.save_qr_image("Testing PNG", "test_png.png", {
    module_size = 10,
    border = 4
})

if success then
    print("✓ " .. message)
else
    print("✗ " .. message)
    print("  (This is expected if no image converter is installed)")
end

-- Test 3: Different sizes
print("\nTest 3: Different module sizes")
for _, size in ipairs({6, 12, 20}) do
    local filename = string.format("test_size_%d.ppm", size)
    success, message = qrimage.save_qr_image("Size Test", filename, {
        module_size = size,
        border = 2
    })
    
    if success then
        print(string.format("✓ Size %d: %s", size, message))
    else
        print(string.format("✗ Size %d: %s", size, message))
    end
end

-- Test 4: Error handling
print("\nTest 4: Error handling")
success, message = qrimage.save_qr_image("", "empty.ppm")
if not success then
    print("✓ Empty string error handled: " .. message)
else
    print("✗ Empty string should have failed")
end

print("\nTest complete. Check generated .ppm files with an image viewer.")
print("PPM files can be opened by most image viewers or converted with:")
print("  convert test_hello.ppm test_hello.png  # ImageMagick")
print("  pnmtopng test_hello.ppm > test_hello.png  # netpbm")