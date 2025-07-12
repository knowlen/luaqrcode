#!/usr/bin/env lua

--- QR Code Image Generator
---
--- Extends the luaqrcode library with native image output capabilities.
--- Generates images in PPM format (pure Lua) and optionally converts to PNG.
---
--- Usage:
---   local qrimage = require("qrimage")
---   qrimage.save_qr_image("Hello World", "output.png")

local qrencode = dofile("qrencode.lua")

local qrimage = {}

--- Write PPM (Portable Pixmap) format image
--- PPM is a simple uncompressed format that Lua can write natively
local function write_ppm(matrix, filename, module_size, border)
    module_size = module_size or 10
    border = border or 4

    if not matrix then
        return false, "No matrix data provided"
    end

    local size = #matrix
    local total_size = size + (2 * border)
    local img_size = total_size * module_size

    local file = io.open(filename, "wb")
    if not file then
        return false, "Could not open file for writing: " .. filename
    end

    -- Write PPM header
    file:write("P6\n")
    file:write(string.format("%d %d\n", img_size, img_size))
    file:write("255\n")

    -- Generate image data
    for img_y = 0, img_size - 1 do
        for img_x = 0, img_size - 1 do
            -- Calculate which module this pixel belongs to
            local module_x = math.floor(img_x / module_size) - border
            local module_y = math.floor(img_y / module_size) - border

            local pixel_value

            -- Check if we're in the border area
            if module_x < 0 or module_x >= size or module_y < 0 or module_y >= size then
                pixel_value = 255  -- White border
            else
                -- matrix is 1-indexed, and matrix[x][y] convention
                if matrix[module_x + 1][module_y + 1] > 0 then
                    pixel_value = 0    -- Black module
                else
                    pixel_value = 255  -- White module
                end
            end

            -- Write RGB pixel (PPM format)
            file:write(string.char(pixel_value, pixel_value, pixel_value))
        end
    end

    file:close()
    return true, string.format("PPM image saved: %dx%d pixels", img_size, img_size)
end

--- Convert PPM to PNG using system tools
local function ppm_to_png(ppm_file, png_file)
    -- Try different conversion tools in order of preference
    local converters = {
        string.format("convert '%s' '%s'", ppm_file, png_file),  -- ImageMagick
        string.format("pnmtopng '%s' > '%s'", ppm_file, png_file),  -- netpbm
        string.format("ffmpeg -i '%s' '%s'", ppm_file, png_file),  -- ffmpeg
    }

    for _, cmd in ipairs(converters) do
        local success = os.execute(cmd .. " 2>/dev/null")
        if success == 0 or success == true then  -- Lua 5.1 vs 5.2+ compatibility
            -- Clean up temporary PPM file
            os.remove(ppm_file)
            return true, "Converted to PNG"
        end
    end

    return false, "No suitable image converter found (tried: convert, pnmtopng, ffmpeg)"
end

--- Save QR code matrix as image file
--- @param matrix table 2D matrix from qrencode.qrcode()
--- @param filename string Output filename (.ppm, .png, etc.)
--- @param options table Optional settings: {module_size=10, border=4}
function qrimage.save_matrix_image(matrix, filename, options)
    options = options or {}
    local module_size = options.module_size or 10
    local border = options.border or 4

    -- Determine output format from filename
    local extension = filename:match("%.([^%.]+)$")
    if not extension then
        return false, "No file extension provided"
    end

    extension = extension:lower()

    if extension == "ppm" then
        -- Direct PPM output
        return write_ppm(matrix, filename, module_size, border)
    elseif extension == "png" or extension == "jpg" or extension == "jpeg" then
        -- Convert via PPM
        local temp_ppm = filename:gsub("%.[^%.]+$", ".tmp.ppm")

        local success, msg = write_ppm(matrix, temp_ppm, module_size, border)
        if not success then
            return false, msg
        end

        local conv_success, conv_msg = ppm_to_png(temp_ppm, filename)
        if not conv_success then
            os.remove(temp_ppm)  -- Clean up on failure
            return false, conv_msg
        end

        return true, string.format("Image saved as %s (%dx%d pixels)",
                                  filename, (#matrix + 2*border) * module_size,
                                  (#matrix + 2*border) * module_size)
    else
        return false, "Unsupported format: " .. extension .. " (supported: ppm, png, jpg, jpeg)"
    end
end

--- Generate QR code and save as image in one step
--- @param text string Text to encode
--- @param filename string Output filename
--- @param options table Optional settings: {module_size=10, border=4, ec_level=nil}
function qrimage.save_qr_image(text, filename, options)
    options = options or {}

    -- Generate QR code matrix
    local ok, matrix = qrencode.qrcode(text, options.ec_level)
    if not ok then
        return false, "QR generation failed: " .. matrix
    end

    -- Save as image
    return qrimage.save_matrix_image(matrix, filename, options)
end

--- Create a simple command-line interface
function qrimage.main(args)
    if not args or #args == 0 then
        print("Usage: lua qrimage.lua <text> [output_file] [module_size] [border]")
        print("   or: lua -e 'require(\"qrimage\").main({\"Hello\", \"test.png\"})'")
        print("")
        print("Examples:")
        print("  lua qrimage.lua \"Hello World\" hello.png")
        print("  lua qrimage.lua \"Test\" test.ppm 8 2")
        return 1
    end

    local text = args[1]
    local filename = args[2] or "qrcode.png"
    local module_size = tonumber(args[3]) or 10
    local border = tonumber(args[4]) or 4

    print(string.format("Generating QR code for: '%s'", text))
    print(string.format("Output: %s (module=%dpx, border=%d)", filename, module_size, border))

    local success, message = qrimage.save_qr_image(text, filename, {
        module_size = module_size,
        border = border
    })

    if success then
        print("✓ " .. message)
        return 0
    else
        print("✗ Error: " .. message)
        return 1
    end
end

-- If running as script, execute main function
if arg and arg[0] and arg[0]:match("qrimage%.lua$") then
    os.exit(qrimage.main(arg))
end

return qrimage