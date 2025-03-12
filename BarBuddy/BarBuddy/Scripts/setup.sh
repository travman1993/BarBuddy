#
//  setup.sh
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

#!/bin/bash

# BarBuddy Setup Script
# This script sets up the development environment for BarBuddy

# Exit on error
set -e

# Print a colored message
function print_message() {
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
    echo -e "${BLUE}$1${NC}"
}

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi

# Check for required tools
print_message "Checking for required tools..."

# Check if CocoaPods is installed
if ! command -v pod &> /dev/null; then
    print_message "CocoaPods not found. Installing..."
    sudo gem install cocoapods
else
    print_message "CocoaPods already installed."
fi

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    print_message "SwiftLint not found. Installing..."
    brew install swiftlint
else
    print_message "SwiftLint already installed."
fi

# Set up git hooks
print_message "Setting up git hooks..."
if [ -d ".git/hooks" ]; then
    cp -f Scripts/git-hooks/pre-commit .git/hooks/
    chmod +x .git/hooks/pre-commit
    print_message "Git hooks installed."
else
    print_message "Git directory not found. Skipping git hooks."
fi

# Install dependencies
print_message "Installing dependencies..."
pod install

print_message "Creating necessary directories..."
mkdir -p Documentation/Screenshots

# Generate project files
print_message "Generating project files..."
swift package generate-xcodeproj

print_message "Setup complete! You're ready to build BarBuddy."
