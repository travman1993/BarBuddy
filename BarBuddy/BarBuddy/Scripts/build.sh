#
//  build.sh
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

#!/bin/bash

# BarBuddy Build Script
# This script builds the app for both iOS and watchOS

# Exit on error
set -e

# Variables
WORKSPACE="BarBuddy.xcworkspace"
SCHEME_IOS="BarBuddy"
SCHEME_WATCHOS="BarBuddyWatch"
CONFIGURATION="Release"
BUILD_DIR="build"

# Print a colored message
function print_message() {
    GREEN='\033[0;32m'
    NC='\033[0m' # No Color
    echo -e "${GREEN}$1${NC}"
}

# Clean build directory
print_message "Cleaning build directory..."
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# Run SwiftLint
print_message "Running SwiftLint..."
swiftlint

# Build iOS app
print_message "Building iOS app..."
xcodebuild \
    -workspace $WORKSPACE \
    -scheme $SCHEME_IOS \
    -configuration $CONFIGURATION \
    -destination "generic/platform=iOS" \
    -archivePath "$BUILD_DIR/BarBuddy.xcarchive" \
    clean archive

# Build watchOS app
print_message "Building watchOS app..."
xcodebuild \
    -workspace $WORKSPACE \
    -scheme $SCHEME_WATCHOS \
    -configuration $CONFIGURATION \
    -destination "generic/platform=watchOS" \
    -archivePath "$BUILD_DIR/BarBuddyWatch.xcarchive" \
    clean archive

print_message "Build completed successfully!"
