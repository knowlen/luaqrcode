# Lua Performance and Build Targets

.PHONY: test bytecode benchmark clean

# Standard test run
test:
	lua tests/run_all.lua

# Compile Lua source to bytecode for faster loading
bytecode:
	@echo "Compiling to bytecode..."
	luac -o qrencode.luac qrencode.lua
	luac -o qrimage.luac qrimage.lua
	luac -o qrcode.luac qrcode.lua
	@echo "Bytecode files created: *.luac"

# Test with LuaJIT (if available)
test-jit:
	@command -v luajit >/dev/null 2>&1 || { echo "LuaJIT not found, install with: sudo apt install luajit"; exit 1; }
	luajit tests/run_all.lua

# Performance benchmarks
benchmark:
	@echo "=== Performance Benchmark ==="
	@echo "Testing with standard Lua:"
	@time lua tests/run_all.lua >/dev/null
	@echo
	@if command -v luajit >/dev/null 2>&1; then \
		echo "Testing with LuaJIT:"; \
		time luajit tests/run_all.lua >/dev/null; \
	else \
		echo "LuaJIT not available for comparison"; \
	fi

# QR generation speed test
speed-test:
	@echo "=== QR Generation Speed Test ==="
	@echo "Generating 100 QR codes with standard Lua:"
	@time lua -e 'qr=dofile("qrimage.lua"); for i=1,100 do qr.save_qr_image("TEST"..i, "/tmp/qr"..i..".ppm") end' 2>/dev/null
	@echo
	@if command -v luajit >/dev/null 2>&1; then \
		echo "Generating 100 QR codes with LuaJIT:"; \
		time luajit -e 'qr=dofile("qrimage.lua"); for i=1,100 do qr.save_qr_image("TEST"..i, "/tmp/qr"..i..".ppm") end' 2>/dev/null; \
	else \
		echo "LuaJIT not available for comparison"; \
	fi
	@rm -f /tmp/qr*.ppm

# Clean up compiled files
clean:
	rm -f *.luac
	rm -f /tmp/qr*.ppm