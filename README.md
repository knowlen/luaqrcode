# Lua QR Code Generator

Pure Lua library for generating QR codes with native image output support.

## Features

- **Pure Lua implementation** - No external dependencies for QR generation
- **Native image output** - Generate PNG, PPM, and other formats directly
- **Multiple interfaces** - Command-line tool and Lua library
- **Production ready** - Mature codebase used in real applications
- **Full QR spec support** - All versions (1-40) and error correction levels

## Installation

### Requirements
- Lua 5.1+ or LuaJIT
- For PNG output: ImageMagick (`convert`) or netpbm (`pnmtopng`) or ffmpeg

### Quick Start
```bash
git clone https://github.com/knowlen/luaqrcode.git
cd luaqrcode
lua qrimage.lua "Hello World" hello.png
```

## Usage

### Command Line Interface
```bash
# Generate PNG image
lua qrimage.lua "Hello World" output.png

# Generate PPM image with custom size
lua qrimage.lua "Test" output.ppm 12 2

# Arguments: <text> [filename] [module_size] [border]
```

### Lua Library Usage
```lua
-- Load the image generation module
local qrimage = dofile("qrimage.lua")

-- Generate QR code image
local success, message = qrimage.save_qr_image("Hello World", "output.png", {
    module_size = 10,  -- pixels per module
    border = 4         -- quiet zone size in modules
})

if success then
    print("✓ " .. message)
else
    print("✗ Error: " .. message)
end
```

### Core Library Only
```lua
-- Use just the QR generation without image output
local qrencode = dofile("qrencode.lua")
local ok, matrix = qrencode.qrcode("Hello World")

if ok then
    -- matrix is 2D array: positive values = black, negative = white
    for y = 1, #matrix do
        for x = 1, #matrix do
            if matrix[x][y] > 0 then
                io.write("██")  -- black module
            else
                io.write("  ")  -- white module
            end
        end
        io.write("\n")
    end
end
```

## File Structure

| File | Purpose |
|------|---------|
| `qrencode.lua` | Core QR code generation library |
| `qrimage.lua` | Image output functionality |
| `qrcode.lua` | Text/ASCII display utilities |
| `qrtest.lua` | Test suite for core library |
| `test_qrimage.lua` | Tests for image generation |

## Testing

```bash
# Test core QR generation
lua qrtest.lua

# Test image generation
lua -e 'dofile("test_qrimage.lua")'
```

## Supported Output Formats

- **PPM** - Generated natively by Lua (no dependencies)
- **PNG** - Converted from PPM using system tools
- **JPEG** - Converted from PPM using system tools

The library automatically detects available conversion tools (ImageMagick, netpbm, ffmpeg) and uses the first one found.

## Error Correction Levels

All standard QR code error correction levels are supported:
- **L** (Low) - ~7% error correction
- **M** (Medium) - ~15% error correction  
- **Q** (Quartile) - ~25% error correction
- **H** (High) - ~30% error correction

## Credits

This is a fork of the original [luaqrcode](https://github.com/speedata/luaqrcode) library created by **Patrick Gundlach** and contributors at speedata. The original library provided the complete QR code generation algorithm implementation.

**Original Authors:**
- Patrick Gundlach (speedata) - Core QR generation algorithm
- Contributors to speedata/luaqrcode - Bug fixes and improvements

**This Fork Adds:**
- Native image output functionality (PPM/PNG/JPEG)
- Command-line interface for image generation
- Pure Lua implementation with no Python dependencies
- Comprehensive test suite for image generation

## License

3-clause BSD license (same as original)

Copyright (c) 2012-2020, Patrick Gundlach (SPEEDATA GMBH) and contributors  
See [License.md](License.md) for full license text.

## Development

This fork maintains compatibility with the original library while adding modern image output capabilities. The core QR generation algorithm remains unchanged from the original implementation.

**Maintenance Status:** Active development (this fork)  
**Original Status:** Maintained for bug fixes only