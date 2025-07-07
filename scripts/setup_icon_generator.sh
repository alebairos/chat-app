#!/bin/bash

# Setup script for App Icon Generator
# Installs required Python dependencies

echo "🎨 Setting up App Icon Generator"
echo "================================"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    echo "Please install Python 3 and try again."
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Check if pip is available
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is required but not installed."
    echo "Please install pip3 and try again."
    exit 1
fi

echo "✅ pip3 found"

# Install Pillow (PIL)
echo "📦 Installing Pillow (PIL) for image processing..."
pip3 install Pillow

if [ $? -eq 0 ]; then
    echo "✅ Pillow installed successfully!"
else
    echo "❌ Failed to install Pillow. Please check your pip3 installation."
    exit 1
fi

# Make the icon generator executable
chmod +x scripts/generate_app_icons.py

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Save your app icon as 'source_icon.png' in the project root"
echo "2. Run: python3 scripts/generate_app_icons.py"
echo ""
echo "💡 The cheerful character image you shared would be perfect for this!" 