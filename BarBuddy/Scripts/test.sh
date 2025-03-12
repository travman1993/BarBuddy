#
//  test.sh
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

#!/bin/bash

# BarBuddy Test Script
# This script runs all the tests for the app

# Exit on error
set -e

# Variables
WORKSPACE="BarBuddy.xcworkspace"
SCHEME_IOS="BarBuddy"
SCHEME_WATCHOS="BarBuddyWatch"
TEST_DESTINATION_IOS="platform=iOS Simulator,name=iPhone 14 Pro,OS=latest"
TEST_DESTINATION_WATCHOS="platform=watchOS Simulator,name=Apple Watch Series 8 (45mm),OS=latest"

# Print a colored message
function print_message() {
    PURPLE='\033[0;35m'
    NC='\033[0m' # No Color
    echo -e "${PURPLE}$1${NC}"
}

# Run iOS tests
print_message "Running iOS unit and UI tests..."
xcodebuild test \
    -workspace $WORKSPACE \
    -scheme $SCHEME_IOS \
    -destination "$TEST_DESTINATION_IOS" \
    -resultBundlePath TestResults/iOS.xcresult

# Run watchOS tests
print_message "Running watchOS unit tests..."
xcodebuild test \
    -workspace $WORKSPACE \
    -scheme $SCHEME_WATCHOS \
    -destination "$TEST_DESTINATION_WATCHOS" \
    -resultBundlePath TestResults/watchOS.xcresult

print_message "All tests completed successfully!"
