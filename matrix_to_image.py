#!/usr/bin/env python3
"""
QR Matrix to Image Converter

Converts the proper QR matrix output from Lua qrencode library to images.
This handles the actual 2D matrix data, not text output.
"""

import sys
import subprocess
from PIL import Image, ImageDraw
import argparse
import json

def lua_qr_to_matrix(text, ec_level=None):
    """
    Generate QR matrix using Lua qrencode library
    
    Args:
        text (str): Text to encode
        ec_level (str): Error correction level
        
    Returns:
        list: 2D matrix or None if failed
    """
    # Create a Lua script to generate matrix data
    lua_script = f'''
    local qrencode = dofile("qrencode.lua")
    local text = "{text}"
    local ok, matrix = qrencode.qrcode(text)
    
    if not ok then
        print("ERROR: " .. matrix)
        os.exit(1)
    end
    
    -- Output matrix as JSON-like format for Python to parse
    print("MATRIX_START")
    print(#matrix)  -- size
    for y = 1, #matrix do
        local row = {{}}
        for x = 1, #matrix[y] do
            table.insert(row, matrix[x][y])
        end
        -- Output row as space-separated values
        print(table.concat(row, " "))
    end
    print("MATRIX_END")
    '''
    
    # Write temp Lua script
    with open('temp_qr_gen.lua', 'w') as f:
        f.write(lua_script)
    
    try:
        # Run Lua script
        result = subprocess.run(['lua', 'temp_qr_gen.lua'], 
                               capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Lua error: {result.stderr}")
            return None
        
        # Parse output
        lines = result.stdout.strip().split('\n')
        
        matrix_start = -1
        matrix_end = -1
        
        for i, line in enumerate(lines):
            if line == "MATRIX_START":
                matrix_start = i
            elif line == "MATRIX_END":
                matrix_end = i
                break
        
        if matrix_start == -1 or matrix_end == -1:
            print("Could not find matrix data in Lua output")
            return None
        
        # Parse matrix
        size = int(lines[matrix_start + 1])
        matrix = []
        
        for i in range(matrix_start + 2, matrix_end):
            row_values = [int(x) for x in lines[i].split()]
            matrix.append(row_values)
        
        print(f"Parsed matrix: {size}x{len(matrix)}")
        return matrix
        
    except Exception as e:
        print(f"Error generating matrix: {e}")
        return None
    finally:
        # Clean up temp file
        try:
            import os
            os.remove('temp_qr_gen.lua')
        except:
            pass

def matrix_to_image(matrix, filename="qr_code.png", module_size=10, border=4):
    """
    Convert QR matrix to image
    
    Args:
        matrix (list): 2D matrix where positive = black, negative = white
        filename (str): Output filename
        module_size (int): Size of each module in pixels
        border (int): Border size in modules (quiet zone)
    """
    if not matrix:
        print("No matrix data provided")
        return False
    
    size = len(matrix)
    
    # Create image with border
    total_size = size + (2 * border)
    img_size = total_size * module_size
    
    print(f"Creating {img_size}x{img_size} image (matrix: {size}x{size}, module: {module_size}px, border: {border})")
    
    # Create white image
    img = Image.new('RGB', (img_size, img_size), 'white')
    draw = ImageDraw.Draw(img)
    
    # Draw QR code
    for y in range(size):
        for x in range(size):
            if matrix[y][x] > 0:  # Positive = black module
                # Calculate position with border
                img_x = (x + border) * module_size
                img_y = (y + border) * module_size
                
                draw.rectangle([
                    img_x, img_y,
                    img_x + module_size - 1, img_y + module_size - 1
                ], fill='black')
    
    # Save image
    img.save(filename)
    print(f"Saved QR code as {filename}")
    
    return True

def test_qr_generation(text):
    """Test the complete pipeline"""
    print(f"Testing QR generation for: '{text}'")
    print("=" * 50)
    
    # Generate matrix
    matrix = lua_qr_to_matrix(text)
    
    if not matrix:
        print("Failed to generate matrix")
        return False
    
    # Convert to image
    success = matrix_to_image(matrix, f"qr_test.png", 
                            module_size=12, border=4)
    
    if not success:
        return False
    
    # Test decoding
    result = subprocess.run(['python', 'qr_decoder_opencv.py', 
                           f"qr_{text.replace(' ', '_')}.png"], 
                          capture_output=True, text=True)
    
    print("Decode result:")
    print(result.stdout)
    
    return "No QR codes were successfully decoded" not in result.stdout

def main():
    parser = argparse.ArgumentParser(description='Generate QR codes using Lua library')
    parser.add_argument('text', help='Text to encode')
    parser.add_argument('--output', '-o', help='Output filename')
    parser.add_argument('--size', '-s', type=int, default=10, help='Module size in pixels')
    parser.add_argument('--border', '-b', type=int, default=4, help='Border size in modules')
    parser.add_argument('--test', action='store_true', help='Test the complete pipeline')
    
    args = parser.parse_args()
    
    if args.test:
        success = test_qr_generation(args.text)
        print(f"\nTest result: {'✅ SUCCESS' if success else '❌ FAILED'}")
        return 0 if success else 1
    
    # Generate matrix
    matrix = lua_qr_to_matrix(args.text)
    
    if not matrix:
        return 1
    
    # Convert to image
    output_file = args.output or "test.png" #f"qr_{args.text.replace(' ', '_')}.png"
    success = matrix_to_image(matrix, output_file, args.size, args.border)
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
