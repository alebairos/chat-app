#!/bin/bash

echo "🔧 Chat Restoration Helper"
echo "========================="
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Run this script from the Flutter project root"
    exit 1
fi

# Generate the restoration code
echo "📝 Generating restoration code..."
dart run scripts/run_restore.dart

echo ""
echo "✅ Restoration code generated!"
echo ""
echo "🎯 Quick Setup Options:"
echo ""
echo "Option 1 - Add to ChatStorageService:"
echo "  1. Copy the executeRestoration() method from scripts/generated_restore_code.dart"
echo "  2. Paste it into lib/services/chat_storage_service.dart"
echo "  3. Call: await ChatStorageService().executeRestoration()"
echo ""
echo "Option 2 - Add to DebugRestore utility:"
echo "  1. Copy the executeRestoration() method"
echo "  2. Paste it into lib/utils/debug_restore.dart"  
echo "  3. Call: await DebugRestore.executeRestoration()"
echo ""
echo "Option 3 - Create a debug button:"
echo "  ElevatedButton("
echo "    onPressed: () async {"
echo "      await executeRestoration();"
echo "      ScaffoldMessenger.of(context).showSnackBar("
echo "        SnackBar(content: Text('Chat restored!')),"
echo "      );"
echo "    },"
echo "    child: Text('Restore Chat'),"
echo "  )"
echo ""
echo "💡 The generated code is Flutter-compatible and ready to use!"
