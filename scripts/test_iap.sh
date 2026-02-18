#!/bin/bash

# IAP Testing Helper Script
# This script helps with In-App Purchase testing

set -e

echo "════════════════════════════════════════════════════════════"
echo "  In-App Purchase Testing Helper"
echo "════════════════════════════════════════════════════════════"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if adb is available
if ! command -v adb &> /dev/null; then
    print_error "adb not found. Please install Android SDK Platform Tools."
    exit 1
fi

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    print_error "No Android device connected. Please connect a device and enable USB debugging."
    exit 1
fi

print_success "Android device detected"

# Menu
echo ""
echo "Select an option:"
echo ""
echo "  1) Clean install (uninstall, clear cache, reinstall)"
echo "  2) Build and install release APK"
echo "  3) Monitor IAP logs"
echo "  4) Clear app data only"
echo "  5) Open Google Play Console in browser"
echo "  6) View IAP diagnostics"
echo "  7) Full test cycle (clean + install + monitor)"
echo ""
read -p "Enter option (1-7): " option

case $option in
    1)
        print_info "Starting clean installation..."

        print_info "Stopping app..."
        adb shell am force-stop com.develop4god.devocional_nuevo 2>/dev/null || true

        print_info "Uninstalling app..."
        adb uninstall com.develop4god.devocional_nuevo 2>/dev/null || true

        print_info "Clearing Play Store cache..."
        adb shell pm clear com.android.vending

        print_info "Building release APK..."
        flutter build apk --release

        print_info "Installing app..."
        adb install build/app/outputs/flutter-apk/app-release.apk

        print_success "Clean installation complete!"
        print_info "Open the app and navigate to Support page to test IAP"
        ;;

    2)
        print_info "Building release APK..."
        flutter build apk --release

        print_info "Installing app..."
        adb install -r build/app/outputs/flutter-apk/app-release.apk

        print_success "Installation complete!"
        ;;

    3)
        print_info "Monitoring IAP logs (press Ctrl+C to stop)..."
        echo ""
        adb logcat | grep -i -E "(IapService|billing|purchase|supporter)" --color=auto
        ;;

    4)
        print_info "Clearing app data..."
        adb shell pm clear com.develop4god.devocional_nuevo
        print_success "App data cleared!"
        ;;

    5)
        print_info "Opening Google Play Console..."
        xdg-open "https://play.google.com/console" 2>/dev/null || open "https://play.google.com/console" 2>/dev/null || echo "Please open: https://play.google.com/console"
        ;;

    6)
        print_info "Starting app to view diagnostics..."
        adb shell am start -n com.develop4god.devocional_nuevo/.MainActivity
        sleep 2
        print_info "Filtering for IAP diagnostics..."
        adb logcat -d | grep -A 30 "IapService.*Diagnostics"
        ;;

    7)
        print_info "Starting full test cycle..."
        echo ""

        # Clean
        print_info "Step 1/5: Stopping app..."
        adb shell am force-stop com.develop4god.devocional_nuevo 2>/dev/null || true

        print_info "Step 2/5: Uninstalling..."
        adb uninstall com.develop4god.devocional_nuevo 2>/dev/null || true
        adb shell pm clear com.android.vending

        print_info "Step 3/5: Building release APK..."
        flutter build apk --release

        print_info "Step 4/5: Installing..."
        adb install build/app/outputs/flutter-apk/app-release.apk

        print_info "Step 5/5: Starting monitoring..."
        print_success "Installation complete! Monitoring logs now..."
        print_warning "Open the app and go to Support page to test purchases"
        echo ""
        adb logcat -c  # Clear old logs
        adb logcat | grep -i -E "(IapService|billing|purchase|supporter)" --color=auto
        ;;

    *)
        print_error "Invalid option"
        exit 1
        ;;
esac

echo ""
print_success "Done!"

