#!/usr/bin/env python3
"""
QR Pipeline Test Script

Tests the complete pipeline: Lua QR generation -> Image conversion -> Decoding
"""

import subprocess
import sys
import os
from PIL import Image
import cv2

def run_command(cmd, input_text=None):
    """Run a shell command and return output"""
    try:
        if input_text:
            result = subprocess.run(cmd, shell=True, input=input_text, 
                                  text=True, capture_output=True)
        else:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def test_qr_pipeline(test_text="Hello World"):
    """Test the complete QR pipeline"""
    print(f"Testing QR pipeline with text: '{test_text}'")
    print("=" * 50)
    
    # Step 1: Generate QR with Lua
    print("Step 1: Generating QR code with Lua...")
    success, qr_text, error = run_command(f'lua qrcode.lua "{test_text}"')
    
    if not success:
        print(f"❌ Lua QR generation failed: {error}")
        return False
    
    print(f"✅ Generated text QR ({len(qr_text.splitlines())} lines)")
    
    # Step 2: Convert to image with better converter
    print("\nStep 2: Converting text to image...")
    success, output, error = run_command('python better_txt_to_qr.py -o test_qr.png -s 8 -b 4', qr_text)
    
    if not success:
        print(f"❌ Image conversion failed: {error}")
        return False
    
    print(f"✅ {output.strip()}")
    
    # Step 3: Verify image was created and check properties
    print("\nStep 3: Checking image properties...")
    try:
        img = Image.open('test_qr.png')
        print(f"✅ Image created: {img.size[0]}x{img.size[1]} pixels, mode: {img.mode}")
        
        # Check if image has good contrast
        import numpy as np
        img_array = np.array(img.convert('L'))  # Convert to grayscale
        unique_values = np.unique(img_array)
        print(f"   Unique pixel values: {len(unique_values)} (should be 2 for pure B&W)")
        print(f"   Min/Max values: {unique_values.min()}/{unique_values.max()}")
        
    except Exception as e:
        print(f"❌ Image check failed: {e}")
        return False
    
    # Step 4: Try decoding with OpenCV
    print("\nStep 4: Decoding with OpenCV...")
    success, output, error = run_command('python qr_decoder_opencv.py test_qr.png')
    
    if "No QR codes were successfully decoded" in output:
        print("❌ OpenCV decoding failed")
        print("Trying debug decoder...")
        
        # Try the debug decoder
        success, debug_output, debug_error = run_command('python qr_debug.py test_qr.png')
        print("Debug output:")
        print(debug_output)
        return False
    else:
        print("✅ OpenCV decoding successful!")
        print(f"Decoded: {output.strip()}")
        return True

def test_different_sizes():
    """Test different module sizes to find what works"""
    print("\n" + "=" * 50)
    print("Testing different module sizes...")
    
    test_text = "test123"
    
    # Generate QR text once
    success, qr_text, error = run_command(f'lua qrcode.lua "{test_text}"')
    if not success:
        print(f"❌ Lua QR generation failed: {error}")
        return
    
    for size in [4, 6, 8, 10, 12, 16, 20]:
        print(f"\nTesting module size {size}...")
        
        # Convert to image
        filename = f'test_qr_{size}.png'
        success, output, error = run_command(f'python better_txt_to_qr.py -o {filename} -s {size} -b 4', qr_text)
        
        if success:
            # Try to decode
            success, decode_output, decode_error = run_command(f'python qr_decoder_opencv.py {filename}')
            
            if "No QR codes were successfully decoded" not in decode_output:
                print(f"✅ Size {size}: SUCCESS - {decode_output.strip()}")
            else:
                print(f"❌ Size {size}: Failed to decode")
        else:
            print(f"❌ Size {size}: Image conversion failed")

def main():
    # Test basic pipeline
    success = test_qr_pipeline("Hello World")
    
    if not success:
        print("\nBasic test failed. Trying different approaches...")
        test_different_sizes()
    
    print(f"\nTest files created: test_qr*.png")
    print("You can manually test these with your phone's QR scanner")

if __name__ == "__main__":
    main()
