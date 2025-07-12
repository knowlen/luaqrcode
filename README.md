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
lua qrimage.lua "Hello World" output.ppm 12 2

# Arguments: <text> [filename] [module_size] [border]
```

**Output:**
> ![Sample QR Code Output](readme_output.png)
> 
> *Generated QR code for "Hello World" (290x290 pixels)*
### Supported Output Formats

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


## Library Usage
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

### Base library only
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

### Core Library
| File | Purpose |
|------|---------|
| `qrencode.lua` | Core QR code generation library |
| `qrimage.lua` | Image output functionality |
| `qrcode.lua` | Text/ASCII display utilities |

### Modern Testing Framework
| File | Purpose |
|------|---------|
| `tests/framework.lua` | Modern test framework with rich assertions |
| `tests/test_core.lua` | Comprehensive core algorithm tests |
| `tests/test_image.lua` | Complete image generation tests |
| `tests/run_all.lua` | Test runner for all suites |

### Legacy Tests (Reference Only)
| File | Purpose |
|------|---------|
| `tests/legacy/qrtest.lua` | Original core library tests |
| `tests/legacy/test_qrimage.lua` | Original image generation tests |

## Testing

```bash
# Run all tests with modern framework
lua tests/run_all.lua

# Individual test suites
lua -e '_G.test_framework = dofile("tests/framework.lua"); dofile("tests/test_core.lua"); _G.test_framework.run()'
lua -e '_G.test_framework = dofile("tests/framework.lua"); dofile("tests/test_image.lua"); _G.test_framework.run()'
```

### Legacy Tests (Reference Only)
```bash
# Original core tests (moved to legacy folder)
lua tests/legacy/qrtest.lua

# Original image tests (moved to legacy folder)
lua -e 'dofile("tests/legacy/test_qrimage.lua")'
```

### Test Features
- **295 comprehensive assertions** covering all functionality
- **23 test suites** with logical organization
- **Rich assertion library** with clear error messages
- **100% test coverage** for both core and image functionality
- **CI-ready** with proper exit codes

## Performance
This library supports multiple Lua implementations with significant performance differences:

### Performance Testing
```bash
# Performance benchmarks
make benchmark      # Compare test suite performance
make speed-test     # Compare QR generation speed
make test-jit       # Run tests with LuaJIT

# Bytecode compilation
make bytecode       # Compile to bytecode for faster loading
make clean          # Remove compiled files
```


| Implementation | Test Suite | QR Generation (100 codes) | Improvement |
|---------------|------------|---------------------------|-------------|
| **Standard Lua** | 0.35s | 1.08s | Baseline |
| **LuaJIT** | 0.14s | 0.16s | **6.6x faster** |
| **Bytecode** | ~0.35s | ~1.08s | Faster loading only |


## Development

### Contributing
This fork maintains compatibility with the original library while adding modern capabilities.

**For external contributors:**
```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/luaqrcode.git
cd luaqrcode
git remote add upstream https://github.com/knowlen/luaqrcode.git

# Create a feature branch
git checkout -b feature-name

# Make changes and test
# ... your modifications ...
lua tests/run_all.lua  # Ensure all tests pass

# Commit and push to your fork
git add .
git commit -m "Your commit message"
git push origin feature-name

# Create a Pull Request on GitHub
```

## Credits

This is a fork of the original [luaqrcode](https://github.com/speedata/luaqrcode) library created by **Patrick Gundlach** and contributors at speedata. The original library provided the complete QR code generation algorithm implementation.

**Original Authors:**
- Patrick Gundlach (speedata) - Core QR generation algorithm
- Contributors to speedata/luaqrcode - Bug fixes and improvements

**This Fork Adds:**
- Native image output functionality (PPM/PNG/JPEG)
- Command-line interface for image generation
- Pure Lua implementation with no Python dependencies
- Modern testing framework with 295 comprehensive assertions
- Professional CI-ready test infrastructure

## License

3-clause BSD license (same as original)

Copyright (c) 2012-2020, Patrick Gundlach (SPEEDATA GMBH) and contributors  
See [License.md](License.md) for full license text.


