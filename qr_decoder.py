#!/usr/bin/env python3
"""
QR Code Image to Text Decoder using OpenCV

This script reads QR code images and extracts the text content.
Uses OpenCV which is widely available and doesn't need zbar.

Requirements:
    pip install opencv-python
    # OR on Arch:
    sudo pacman -S python-opencv

Usage:
    python qr_decoder_opencv.py image.png
    python qr_decoder_opencv.py *.png
"""

import sys
import argparse
import glob
import os

try:
    import cv2
    print("✓ Using OpenCV for QR decoding")
except ImportError:
    print("✗ OpenCV not found!")
    print("Install with:")
    print("  pip install opencv-python")
    print("  # OR on Arch: sudo pacman -S python-opencv")
    sys.exit(1)

def decode_qr_image(image_path):
    """
    Decode QR code from an image file using OpenCV
    
    Args:
        image_path (str): Path to the image file
        
    Returns:
        list: List of decoded data from QR codes found in image
    """
    try:
        # Read the image
        image = cv2.imread(image_path)
        if image is None:
            print(f"Could not read image: {image_path}")
            return []
        
        # Initialize QR code detector
        detector = cv2.QRCodeDetector()
        
        # Detect and decode QR codes
        data, points, straight_qr = detector.detectAndDecode(image)
        
        results = []
        if data:
            results.append({
                'data': data,
                'type': 'QRCODE',
                'points': points.tolist() if points is not None else None
            })
        
        return results
        
    except Exception as e:
        print(f"Error processing {image_path}: {e}")
        return []

def decode_multiple_images(image_paths):
    """
    Decode QR codes from multiple image files
    
    Args:
        image_paths (list): List of image file paths
    """
    for image_path in image_paths:
        if not os.path.exists(image_path):
            print(f"File not found: {image_path}")
            continue
            
        print(f"\n--- Decoding: {image_path} ---")
        
        results = decode_qr_image(image_path)
        
        if results:
            for i, result in enumerate(results):
                print(f"QR Code #{i+1}:")
                print(f"  Type: {result['type']}")
                print(f"  Data: {result['data']}")
                if result['points']:
                    print(f"  Corner points found: {len(result['points'])} points")
        else:
            print("  No QR codes found in this image")

def main():
    parser = argparse.ArgumentParser(description='Decode QR codes from image files using OpenCV')
    parser.add_argument('images', nargs='+', help='Image file(s) to decode')
    parser.add_argument('--output', '-o', help='Output decoded text to file')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    # Expand glob patterns
    image_files = []
    for pattern in args.images:
        if '*' in pattern or '?' in pattern:
            image_files.extend(glob.glob(pattern))
        else:
            image_files.append(pattern)
    
    if not image_files:
        print("No image files found!")
        return 1
    
    # Decode images
    all_decoded_text = []
    
    for image_path in image_files:
        if not os.path.exists(image_path):
            print(f"File not found: {image_path}")
            continue
            
        if args.verbose:
            print(f"\n--- Decoding: {image_path} ---")
        
        results = decode_qr_image(image_path)
        
        if results:
            for i, result in enumerate(results):
                decoded_text = result['data']
                all_decoded_text.append(decoded_text)
                
                if args.verbose:
                    print(f"QR Code #{i+1}:")
                    print(f"  Type: {result['type']}")
                    if result['points']:
                        print(f"  Corner points: {result['points']}")
                
                print(f"Text: {decoded_text}")
        else:
            if args.verbose:
                print("No QR codes found in this image")
    
    # Output to file if requested
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            for text in all_decoded_text:
                f.write(text + '\n')
        print(f"\nDecoded text saved to: {args.output}")
    
    if not all_decoded_text:
        print("\nNo QR codes were successfully decoded.")
        return 1
    
    return 0

# Simple function for programmatic use
def decode_qr_simple(image_path):
    """
    Simple function to get just the text from a QR code image
    
    Args:
        image_path (str): Path to image file
        
    Returns:
        str: Decoded text, or None if no QR code found
    """
    results = decode_qr_image(image_path)
    if results:
        return results[0]['data']
    return None

if __name__ == "__main__":
    sys.exit(main())
