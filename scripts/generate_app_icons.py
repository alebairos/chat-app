#!/usr/bin/env python3
"""
App Icon Generator Script
Generates all required app icon sizes for Flutter multi-platform deployment

Usage:
1. Save your source icon as 'source_icon.png' (1024x1024px recommended)
2. Run: python3 scripts/generate_app_icons.py
3. Icons will be generated in their respective platform directories

Requirements:
- Python 3.6+
- Pillow (PIL): pip install Pillow
"""

import os
import sys
from PIL import Image, ImageDraw
import json

# Define all required icon sizes for each platform
ICON_SIZES = {
    'ios': {
        # iOS App Store and various device sizes
        'Icon-App-1024x1024@1x.png': (1024, 1024),
        'Icon-App-20x20@1x.png': (20, 20),
        'Icon-App-20x20@2x.png': (40, 40),
        'Icon-App-20x20@3x.png': (60, 60),
        'Icon-App-29x29@1x.png': (29, 29),
        'Icon-App-29x29@2x.png': (58, 58),
        'Icon-App-29x29@3x.png': (87, 87),
        'Icon-App-40x40@1x.png': (40, 40),
        'Icon-App-40x40@2x.png': (80, 80),
        'Icon-App-40x40@3x.png': (120, 120),
        'Icon-App-60x60@2x.png': (120, 120),
        'Icon-App-60x60@3x.png': (180, 180),
        'Icon-App-76x76@1x.png': (76, 76),
        'Icon-App-76x76@2x.png': (152, 152),
        'Icon-App-83.5x83.5@2x.png': (167, 167),
    },
    'android': {
        # Android launcher icons (traditional)
        'mipmap-mdpi/ic_launcher.png': (48, 48),
        'mipmap-hdpi/ic_launcher.png': (72, 72),
        'mipmap-xhdpi/ic_launcher.png': (96, 96),
        'mipmap-xxhdpi/ic_launcher.png': (144, 144),
        'mipmap-xxxhdpi/ic_launcher.png': (192, 192),
    },
    'web': {
        # Web/PWA icons
        'favicon.png': (32, 32),
        'icons/Icon-192.png': (192, 192),
        'icons/Icon-512.png': (512, 512),
        'icons/Icon-maskable-192.png': (192, 192),
        'icons/Icon-maskable-512.png': (512, 512),
    },
    'macos': {
        # macOS app icons
        'AppIcon.appiconset/app_icon_16.png': (16, 16),
        'AppIcon.appiconset/app_icon_32.png': (32, 32),
        'AppIcon.appiconset/app_icon_64.png': (64, 64),
        'AppIcon.appiconset/app_icon_128.png': (128, 128),
        'AppIcon.appiconset/app_icon_256.png': (256, 256),
        'AppIcon.appiconset/app_icon_512.png': (512, 512),
        'AppIcon.appiconset/app_icon_1024.png': (1024, 1024),
    }
}

def create_rounded_icon(image, corner_radius_percent=22):
    """
    Create iOS-style rounded rectangle icon
    corner_radius_percent: iOS uses ~22% corner radius
    """
    size = image.size[0]  # Assume square image
    corner_radius = int(size * corner_radius_percent / 100)
    
    # Create a mask for rounded corners
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size-1, size-1)], corner_radius, fill=255)
    
    # Apply the mask
    result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    result.paste(image, (0, 0))
    result.putalpha(mask)
    
    return result

def create_maskable_icon(image, safe_zone_percent=80):
    """
    Create maskable icon with safe zone for Android adaptive icons
    safe_zone_percent: Content should fit within 80% of the canvas
    """
    size = image.size[0]
    safe_size = int(size * safe_zone_percent / 100)
    
    # Create white background
    result = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    
    # Resize image to fit safe zone
    resized_image = image.resize((safe_size, safe_size), Image.Resampling.LANCZOS)
    
    # Center the image
    offset = (size - safe_size) // 2
    result.paste(resized_image, (offset, offset), resized_image if resized_image.mode == 'RGBA' else None)
    
    return result

def generate_icons(source_path):
    """Generate all app icons from source image"""
    
    if not os.path.exists(source_path):
        print(f"❌ Source image not found: {source_path}")
        print("Please save your icon as 'source_icon.png' in the project root")
        return False
    
    try:
        # Load and validate source image
        source_image = Image.open(source_path)
        print(f"✅ Loaded source image: {source_image.size}")
        
        # Convert to RGBA if needed
        if source_image.mode != 'RGBA':
            source_image = source_image.convert('RGBA')
        
        # Ensure square image
        if source_image.size[0] != source_image.size[1]:
            print("⚠️  Source image is not square. Cropping to square...")
            min_size = min(source_image.size)
            source_image = source_image.crop((0, 0, min_size, min_size))
        
        total_icons = sum(len(sizes) for sizes in ICON_SIZES.values())
        current_icon = 0
        
        # Generate iOS icons
        print(f"\n📱 Generating iOS icons...")
        ios_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
        for filename, size in ICON_SIZES['ios'].items():
            current_icon += 1
            print(f"  [{current_icon}/{total_icons}] {filename} ({size[0]}x{size[1]})")
            
            # Resize image
            resized = source_image.resize(size, Image.Resampling.LANCZOS)
            
            # Apply iOS rounded corners for larger sizes
            if size[0] >= 60:
                resized = create_rounded_icon(resized)
            
            # Convert to RGB for iOS (no transparency)
            final_image = Image.new('RGB', size, (255, 255, 255))
            if resized.mode == 'RGBA':
                final_image.paste(resized, (0, 0), resized)
            else:
                final_image.paste(resized, (0, 0))
            
            # Save
            output_path = os.path.join(ios_dir, filename)
            final_image.save(output_path, 'PNG', optimize=True)
        
        # Generate Android icons
        print(f"\n🤖 Generating Android icons...")
        android_base = "android/app/src/main/res"
        for path, size in ICON_SIZES['android'].items():
            current_icon += 1
            print(f"  [{current_icon}/{total_icons}] {path} ({size[0]}x{size[1]})")
            
            # Resize image
            resized = source_image.resize(size, Image.Resampling.LANCZOS)
            
            # Convert to RGB with white background
            final_image = Image.new('RGB', size, (255, 255, 255))
            if resized.mode == 'RGBA':
                final_image.paste(resized, (0, 0), resized)
            else:
                final_image.paste(resized, (0, 0))
            
            # Save
            output_path = os.path.join(android_base, path)
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            final_image.save(output_path, 'PNG', optimize=True)
        
        # Generate Web icons
        print(f"\n🌐 Generating Web icons...")
        web_dir = "web"
        for filename, size in ICON_SIZES['web'].items():
            current_icon += 1
            print(f"  [{current_icon}/{total_icons}] {filename} ({size[0]}x{size[1]})")
            
            # Resize image
            resized = source_image.resize(size, Image.Resampling.LANCZOS)
            
            # Create maskable version for maskable icons
            if 'maskable' in filename:
                resized = create_maskable_icon(resized)
            
            # Convert to RGB with white background
            final_image = Image.new('RGB', size, (255, 255, 255))
            if resized.mode == 'RGBA':
                final_image.paste(resized, (0, 0), resized)
            else:
                final_image.paste(resized, (0, 0))
            
            # Save
            output_path = os.path.join(web_dir, filename)
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            final_image.save(output_path, 'PNG', optimize=True)
        
        # Generate macOS icons
        print(f"\n🖥️  Generating macOS icons...")
        macos_dir = "macos/Runner/Assets.xcassets"
        for path, size in ICON_SIZES['macos'].items():
            current_icon += 1
            print(f"  [{current_icon}/{total_icons}] {path} ({size[0]}x{size[1]})")
            
            # Resize image
            resized = source_image.resize(size, Image.Resampling.LANCZOS)
            
            # Apply rounded corners for macOS
            if size[0] >= 32:
                resized = create_rounded_icon(resized, corner_radius_percent=18)
            
            # Convert to RGB with white background
            final_image = Image.new('RGB', size, (255, 255, 255))
            if resized.mode == 'RGBA':
                final_image.paste(resized, (0, 0), resized)
            else:
                final_image.paste(resized, (0, 0))
            
            # Save
            output_path = os.path.join(macos_dir, path)
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            final_image.save(output_path, 'PNG', optimize=True)
        
        print(f"\n✅ Successfully generated {total_icons} app icons!")
        print("\n📋 Next steps:")
        print("1. Test the app on iOS and Android devices")
        print("2. Verify icons appear correctly in all contexts")
        print("3. Update app store listings with new screenshots")
        
        return True
        
    except Exception as e:
        print(f"❌ Error generating icons: {e}")
        return False

def main():
    print("🎨 App Icon Generator")
    print("=" * 50)
    
    # Check if we're in the right directory
    if not os.path.exists('pubspec.yaml'):
        print("❌ Please run this script from the Flutter project root directory")
        sys.exit(1)
    
    # Check for source image
    source_path = 'source_icon.png'
    
    if not os.path.exists(source_path):
        print(f"📝 Instructions:")
        print(f"1. Save your app icon as '{source_path}' in the project root")
        print(f"2. Recommended size: 1024x1024px")
        print(f"3. Format: PNG with transparency support")
        print(f"4. Run this script again")
        print(f"\n💡 Tip: The cheerful character image you shared would be perfect!")
        return
    
    # Generate icons
    success = generate_icons(source_path)
    
    if success:
        print(f"\n🚀 Ready to test! Run:")
        print(f"   flutter clean")
        print(f"   flutter run")
    else:
        print(f"\n❌ Icon generation failed. Please check the error messages above.")

if __name__ == "__main__":
    main() 