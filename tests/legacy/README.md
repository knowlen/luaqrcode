# Legacy Tests

These are the original test files from the project, preserved for reference.

**⚠️ These tests have been superseded by the modern testing framework.**

## Use the Modern Framework Instead

```bash
# Run all modern tests
lua tests/run_all.lua
```

The modern framework provides:
- 295 comprehensive assertions (vs ~80 in legacy)
- Better error reporting and colored output
- Structured test organization  
- 100% test coverage including image functionality

## Legacy Files

- `qrtest.lua` - Original core QR algorithm tests
- `test_qrimage.lua` - Original image generation tests

These files are kept for reference and to understand the original test approach, but the modern framework in the parent `tests/` directory should be used for all development and validation.