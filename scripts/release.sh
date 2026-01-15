#!/usr/bin/env bash

# Follows global best practices (Fallback Protocol)

# === Auto install gum if not found ===
if ! command -v gum &>/dev/null; then
  echo "🧩 gum CLI not found. Installing gum..."
  brew tap charmbracelet/tap
  brew install gum

  if ! command -v gum &>/dev/null; then
    echo "❌ Failed to install gum. Please install it manually."
    exit 1
  else
    echo "✅ gum installed successfully."
  fi
fi

# === UI CLI ===
flavor=$(gum choose --header="Select flavor:" alpha dev prg uat prd)
bump_version=$(gum choose --header="Bump version?" "patch (x.y.Z)" "minor (x.Y.0)" "major (X.0.0)" no "set manually")
bump_build=$(gum choose --header="Bump build number(x.y.z(CODE))?" yes no "set manually")
generate=$(gum choose --header="Generate code/assets?" yes no)
build_ios=$(gum choose --header="Build for iOS?" yes no)
build_android=$(gum choose --header="Build for Android?" yes no)
push_tag=$(gum choose --header="Push Git tag after build?" yes no)

# Get version if set manually
if [ "$bump_version" == "set manually" ]; then
  bump_version=$(gum input --placeholder "Enter version e.g. 1.2.3" --header "Set custom version:")
fi

if [ "$bump_build" == "set manually" ]; then
  bump_build=$(gum input --placeholder "Enter build number e.g. 42" --header "Set custom build number:")
fi

export_method="development"
if [ "$flavor" == "prd" ]; then
  export_method="app-store"
fi

# === Show config summary ===
gum format --theme=pink <<EOF
# 🚀 Build Configuration

- **Flavor**: \`$flavor\`
- **Bump Version**: \`$bump_version\`
- **Bump Build Number**: \`$bump_build\`
- **Generate Code/Assets**: \`$generate\`
- **Build iOS**: \`$build_ios\`
- **Build Android**: \`$build_android\`
- **Export Method**: \`$export_method\`
- **Push Git Tag**: \`$push_tag\`

Starting in 3 seconds...
EOF

sleep 3

# === VALIDATIONS ===
echo "🔧 Validating setup..."

# Validate yq installation
if ! sh scripts/yq_validator.sh; then
  gum style --foreground 196 --bold "❌ yq validation failed!"
  echo ""
  echo "🔍 yq is required for parsing YAML files (pubspec.yaml)"
  echo "💡 Install yq: brew install yq"
  exit 1
fi

# Validate mag installation  
if ! sh scripts/mag_validator.sh; then
  gum style --foreground 196 --bold "❌ mag validation failed!"
  echo ""
  echo "🔍 mag tool is required for version management"
  echo "💡 Install mag or check mag_validator.sh for installation instructions"
  exit 1
fi

gum style --foreground 46 "✅ Validation completed successfully"

# === Version Bumping ===
if [ "$bump_version" == "patch (x.y.Z)" ]; then
  if ! mag modify bump --targets patch; then
    gum style --foreground 196 --bold "❌ Failed to bump patch version!"
    echo ""
    echo "🔍 Possible causes:"
    echo "  • mag tool not properly configured"
    echo "  • Invalid version format in pubspec.yaml"
    echo "  • File permission issues"
    echo ""
    echo "💡 Try these solutions:"
    echo "  • Check mag configuration"
    echo "  • Verify pubspec.yaml version format"
    echo "  • Run: mag --help for more information"
    exit 1
  fi
  gum style --foreground 46 "✅ Patch version bumped successfully"
elif [ "$bump_version" == "minor (x.Y.0)" ]; then
  if ! mag modify bump --targets minor; then
    gum style --foreground 196 --bold "❌ Failed to bump minor version!"
    echo ""
    echo "🔍 Possible causes:"
    echo "  • mag tool not properly configured"
    echo "  • Invalid version format in pubspec.yaml"
    echo "  • File permission issues"
    echo ""
    echo "💡 Try these solutions:"
    echo "  • Check mag configuration"
    echo "  • Verify pubspec.yaml version format"
    echo "  • Run: mag --help for more information"
    exit 1
  fi
  gum style --foreground 46 "✅ Minor version bumped successfully"
elif [ "$bump_version" == "major (X.0.0)" ]; then
  if ! mag modify bump --targets major; then
    gum style --foreground 196 --bold "❌ Failed to bump major version!"
    echo ""
    echo "🔍 Possible causes:"
    echo "  • mag tool not properly configured"
    echo "  • Invalid version format in pubspec.yaml"
    echo "  • File permission issues"
    echo ""
    echo "💡 Try these solutions:"
    echo "  • Check mag configuration"
    echo "  • Verify pubspec.yaml version format"
    echo "  • Run: mag --help for more information"
    exit 1
  fi
  gum style --foreground 46 "✅ Major version bumped successfully"
elif [ "$bump_version" == "set manually" ]; then
  if ! mag modify set --ver "$bump_version"; then
    gum style --foreground 196 --bold "❌ Failed to set custom version: $bump_version"
    echo ""
    echo "🔍 Possible causes:"
    echo "  • Invalid version format (should be x.y.z)"
    echo "  • mag tool configuration issues"
    echo "  • File permission issues"
    echo ""
    echo "💡 Try these solutions:"
    echo "  • Use semantic version format (e.g., 1.2.3)"
    echo "  • Check pubspec.yaml write permissions"
    echo "  • Verify mag tool installation"
    exit 1
  fi
  gum style --foreground 46 "✅ Version set to: $bump_version"
fi

if [ "$bump_build" == "yes" ]; then
  if ! mag modify bump --targets build-number; then
    gum style --foreground 196 --bold "❌ Failed to bump build number!"
    echo ""
    echo "🔍 Possible causes:"
    echo "  • mag tool not properly configured"
    echo "  • Invalid build number format in pubspec.yaml"
    echo "  • File permission issues"
    exit 1
  fi
  gum style --foreground 46 "✅ Build number bumped successfully"
elif [ "$bump_build" != "no" ]; then
  if ! mag modify set --build "$bump_build"; then
    gum style --foreground 196 --bold "❌ Failed to set custom build number: $bump_build"
    echo ""
    echo "🔍 Possible causes:"
    echo "  • Invalid build number format (should be numeric)"
    echo "  • mag tool configuration issues"
    echo "  • File permission issues"
    echo ""
    echo "💡 Try these solutions:"
    echo "  • Use numeric build number (e.g., 42)"
    echo "  • Check pubspec.yaml write permissions"
    echo "  • Verify mag tool installation"
    exit 1
  fi
  gum style --foreground 46 "✅ Build number set to: $bump_build"
fi

# === Prepare filenames ===
app_name=$(yq '.name' pubspec.yaml)
if [ -z "$app_name" ] || [ "$app_name" == "null" ]; then
  gum style --foreground 196 --bold "❌ Failed to read app name from pubspec.yaml"
  echo ""
  echo "🔍 Check that pubspec.yaml contains a valid 'name' field"
  exit 1
fi

version=$(yq '.version' pubspec.yaml)
if [ -z "$version" ] || [ "$version" == "null" ]; then
  gum style --foreground 196 --bold "❌ Failed to read version from pubspec.yaml"
  echo ""
  echo "🔍 Check that pubspec.yaml contains a valid 'version' field (e.g., 1.0.0+1)"
  exit 1
fi

version=${version//+/_}
file_name="${app_name}_${flavor}_${version}"

gum style --foreground 212 --bold "📦 Preparing build: $file_name"

# === Setup Distribution Folder ===
setup_distribution_folder() {
  # Create timestamp for this build session
  timestamp=$(date +"%Y%m%d_%H%M%S")
  distribution_root="distribution"
  distribution_path="$distribution_root/${file_name}_${timestamp}"
  distribution_name="${file_name}_${timestamp}"
  
  # Create main distribution directory
  if ! mkdir -p "$distribution_path"; then
    gum style --foreground 196 --bold "❌ Failed to create distribution folder"
    echo ""
    echo "🔍 Possible causes:"
    echo "  • Permission issues in project directory"
    echo "  • Disk space issues"
    echo ""
    echo "💡 Try these solutions:"
    echo "  • Check directory write permissions"
    echo "  • Free up disk space"
    exit 1
  fi
  
  # Create build info file
  cat > "$distribution_path/build_info.txt" << EOF
# Build Information
Build Date: $(date)
Flavor: $flavor
Version: $version
App Name: $app_name
File Name: $file_name
Export Method: $export_method

# Build Configuration
Generate Assets: $generate
Build iOS: $build_ios
Build Android: $build_android
Push Tag: $push_tag
EOF
  
  gum style --foreground 135 --bold "📦 Distribution: $distribution_name"
  echo ""
}

generate_assets() {
  # Get dependencies with error handling
  if ! gum spin --spinner dot --title "Getting dependencies..." -- flutter pub get; then
    gum style --foreground 196 --bold "❌ Failed to get Flutter dependencies!"
    echo ""
    echo "🔍 Possible causes:"
    echo "  • Network connectivity issues"
    echo "  • Invalid pubspec.yaml configuration"
    echo "  • Flutter SDK issues"
    echo "  • Conflicting package versions"
    echo ""
    echo "💡 Try these solutions:"
    echo "  • Run: flutter doctor"
    echo "  • Check your internet connection"
    echo "  • Validate pubspec.yaml syntax"
    echo "  • Run: flutter clean && flutter pub cache repair"
    exit 1
  fi

  # Run build_runner with error handling
  if ! gum spin --spinner dot --title "Running build_runner..." -- dart run build_runner build --delete-conflicting-outputs; then
    gum style --foreground 196 --bold "❌ Code generation failed!"
    echo ""
    echo "🔍 Possible causes:"
    echo "  • Syntax errors in Dart files"
    echo "  • Missing build_runner dependencies"
    echo "  • Conflicting generated files"
    echo "  • Invalid annotations or configurations"
    echo ""
    echo "💡 Try these solutions:"
    echo "  • Check for syntax errors in your Dart files"
    echo "  • Run: flutter clean"
    echo "  • Run: dart run build_runner clean"
    echo "  • Verify build_runner configuration in pubspec.yaml"
    exit 1
  fi

  # Generate custom assets with error handling
  if ! gum spin --spinner dot --title "Generating custom assets..." -- sh scripts/generate_assets.sh; then
    gum style --foreground 196 --bold "❌ Custom asset generation failed!"
    echo ""
    echo "🔍 Possible causes:"
    echo "  • Missing asset files"
    echo "  • Invalid asset generation script"
    echo "  • Permission issues with asset directories"
    echo ""
    echo "💡 Try these solutions:"
    echo "  • Check scripts/generate_assets.sh exists and is executable"
    echo "  • Verify asset files in assets/ directory"
    echo "  • Check file permissions: chmod +x scripts/generate_assets.sh"
    exit 1
  fi
  
  gum style --foreground 46 "✅ Asset generation completed successfully"
}

# === Setup Distribution Folder ===
setup_distribution_folder

# === Code Generation ===
if [ "$generate" == "yes" ]; then
  generate_assets
fi

# === Android Build ===
if [ "$build_android" == "yes" ]; then
  gum style --foreground 46 --bold "🤖 Building Android APK..."
  temp_apk_path="build/app/outputs/flutter-apk/${file_name}.apk"

  # Build APK with detailed logging and root-cause analysis on failure
  temp_build_log=$(mktemp -t flutter_build_XXXX).log
  set -o pipefail
  if flutter build apk --flavor "$flavor" 2>&1 | tee "$temp_build_log"; then
    # Rename and move APK to distribution folder
    if mv "build/app/outputs/flutter-apk/app-${flavor}-release.apk" "$temp_apk_path" 2>/dev/null; then
      if mv "$temp_apk_path" "$distribution_path/" 2>/dev/null; then
        gum style --foreground 46 "   ✅ APK build completed"
      else
        gum style --foreground 196 --bold "❌ Failed to move APK file to distribution folder"
        exit 1
      fi
    else
      gum style --foreground 196 --bold "❌ Failed to rename APK file"
      echo "Expected source: build/app/outputs/flutter-apk/app-${flavor}-release.apk"
      echo "Expected destination: $temp_apk_path"
      ls -la build/app/outputs/flutter-apk/ || echo "APK output directory not found"
      exit 1
    fi
  else
    gum style --foreground 196 --bold "❌ Android APK build failed! Root cause:"
    # Try to detect specific root causes from the log
    if grep -qi "ProductFlavor with name '\?$flavor\?' not found\|No matching variant of project" "$temp_build_log"; then
      echo "• Invalid or missing product flavor: '$flavor' in android/app/build.gradle"
    elif grep -qi "Could not get unknown property 'APP_ID'\|applicationId .* is not a valid" "$temp_build_log"; then
      echo "• Missing/invalid APP_ID from environment (.env.$flavor)"
    elif grep -qi "Keystore file not found\|Keystore was tampered with\|Failed to read key" "$temp_build_log"; then
      echo "• Android signing configuration/keystore issue"
    elif grep -qi "Could not resolve\|Could not find com.android.tools\|failed to find Build Tools" "$temp_build_log"; then
      echo "• Android SDK/Gradle dependency resolution issue"
    elif grep -qi "A problem occurred evaluating project ':app'" "$temp_build_log"; then
      echo "• Gradle script error in android/app/build.gradle"
    else
      echo "• See last lines of build log below:"
      tail -n 50 "$temp_build_log"
    fi
    echo ""
    echo "Log saved: $temp_build_log"
    echo "💡 Common fixes: flutter doctor; flutter clean && flutter pub get; verify .env.$flavor and signing configs"
    exit 1
  fi

  # Build AAB for production with proper error handling
  if [ "$flavor" == "prd" ]; then
    gum style --foreground 220 --bold "📦 Building Android App Bundle (.aab)..."
    temp_aab_path="build/app/outputs/bundle/${flavor}Release/${file_name}.aab"
    
    if gum spin --spinner minidot --title "Building AAB..." -- flutter build appbundle --flavor "$flavor"; then
      # Rename and move AAB to distribution folder
      if mv "build/app/outputs/bundle/${flavor}Release/app-${flavor}-release.aab" "$temp_aab_path" 2>/dev/null; then
        if mv "$temp_aab_path" "$distribution_path/" 2>/dev/null; then
          gum style --foreground 220 "   ✅ AAB build completed"
        else
          gum style --foreground 196 --bold "❌ Failed to move AAB file to distribution folder"
          exit 1
        fi
      else
        gum style --foreground 196 --bold "❌ Failed to rename AAB file"
        echo "Expected source: build/app/outputs/bundle/${flavor}Release/app-${flavor}-release.aab"
        echo "Expected destination: $temp_aab_path"
        ls -la "build/app/outputs/bundle/${flavor}Release/" || echo "AAB output directory not found"
        exit 1
      fi
    else
      gum style --foreground 196 --bold "❌ Android App Bundle (.aab) build failed!"
      echo ""
      echo "🔍 Possible causes:"
      echo "  • Missing Android SDK or build tools"
      echo "  • Invalid production flavor configuration"
      echo "  • Gradle sync issues"
      echo "  • Missing app signing configuration for Play Store"
      echo ""
      echo "💡 Try these solutions:"
      echo "  • Run: flutter doctor"
      echo "  • Run: flutter clean && flutter pub get"
      echo "  • Check android/app/build.gradle for production signing config"
      echo "  • Verify Play Store upload key configuration"
      exit 1
    fi
  fi
fi

# === iOS Build ===
if [ "$build_ios" == "yes" ]; then
  gum style --foreground 51 --bold "🍏 Building iOS IPA..."
  
  # Validate Firebase setup first
  if ! sh scripts/flutterfire_validator.sh >/dev/null 2>&1; then
    gum style --foreground 196 --bold "❌ Firebase configuration validation failed!"
    echo ""
    echo "🔍 Firebase setup issues detected:"
    echo "  • Missing or invalid Firebase configuration"
    echo "  • Run: sh scripts/flutterfire_validator.sh for details"
    exit 1
  fi
  
  temp_ipa_path="build/ios/ipa/${file_name}.ipa"

  # Build IPA with detailed logging and root-cause analysis on failure
  build_success=false
  ios_build_log=$(mktemp -t flutter_ios_build_XXXX).log
  set -o pipefail
  if [ "$export_method" == "app-store" ]; then
    if flutter build ipa --release --export-options-plist scripts/export.plist --flavor "$flavor" 2>&1 | tee "$ios_build_log"; then
      build_success=true
    else
      gum style --foreground 196 --bold "❌ iOS IPA build failed (App Store)! Root cause:"
      if grep -qi "No signing certificate" "$ios_build_log"; then
        echo "• Missing or invalid App Store distribution certificate"
      elif grep -qi "Provisioning profile" "$ios_build_log" | grep -qi "doesn't include"; then
        echo "• Provisioning profile mismatch (bundle id/devices/cert)"
      elif grep -qi "exportOptionsPlist" "$ios_build_log"; then
        echo "• Missing/invalid export options (scripts/export.plist)"
      elif grep -qi "The provided entity includes an attribute with an invalid value" "$ios_build_log"; then
        echo "• Invalid build settings for App Store (check signing and bundle id)"
      elif grep -qi "No such file or directory" "$ios_build_log" | grep -qi "export.plist"; then
        echo "• export.plist path invalid"
      elif grep -qi "Runner" "$ios_build_log" | grep -qi "Signing for"; then
        echo "• Xcode signing settings not configured for Runner (targets/schemes)"
      else
        echo "• See last lines of build log below:"
        tail -n 80 "$ios_build_log"
      fi
      echo ""
      echo "Log saved: $ios_build_log"
      exit 1
    fi
  else
    if flutter build ipa --release --export-options-plist scripts/export_development.plist --flavor "$flavor" 2>&1 | tee "$ios_build_log"; then
      build_success=true
    else
      gum style --foreground 196 --bold "❌ iOS IPA build failed (Development)! Root cause:"
      if grep -qi "No signing certificate" "$ios_build_log"; then
        echo "• Missing or invalid iOS development certificate"
      elif grep -qi "Provisioning profile" "$ios_build_log" | grep -qi "doesn't include"; then
        echo "• Development provisioning profile mismatch (bundle id/devices/cert)"
      elif grep -qi "exportOptionsPlist" "$ios_build_log"; then
        echo "• Missing/invalid export options (scripts/export_development.plist)"
      elif grep -qi "device .* is not registered" "$ios_build_log"; then
        echo "• Test device not registered in Apple Developer portal"
      elif grep -qi "No such file or directory" "$ios_build_log" | grep -qi "export_development.plist"; then
        echo "• export_development.plist path invalid"
      elif grep -qi "Signing for .* requires a development team" "$ios_build_log"; then
        echo "• Xcode project missing Development Team for signing"
      else
        echo "• See last lines of build log below:"
        tail -n 80 "$ios_build_log"
      fi
      echo ""
      echo "Log saved: $ios_build_log"
      exit 1
    fi
  fi

  # Rename and move IPA file to distribution folder
  if [ "$build_success" = true ]; then
    # Rename IPA file first
    if mv "build/ios/ipa/$app_name.ipa" "$temp_ipa_path" 2>/dev/null; then
      # Move to distribution folder
      if mv "$temp_ipa_path" "$distribution_path/" 2>/dev/null; then
        gum style --foreground 51 "   ✅ IPA build completed"
      else
        gum style --foreground 196 --bold "❌ Failed to move IPA file to distribution folder"
        exit 1
      fi
    else
      gum style --foreground 196 --bold "❌ Failed to rename IPA file"
      echo "Expected source: build/ios/ipa/$app_name.ipa"
      echo "Expected destination: $temp_ipa_path"
      ls -la build/ios/ipa/ || echo "IPA output directory not found"
      echo ""
      echo "🔍 The build may have succeeded but the IPA file location is unexpected."
      echo "Check build/ios/ipa/ directory for the actual IPA file."
      exit 1
    fi
  fi
fi

# === Git Tag ===
if [ "$push_tag" == "yes" ]; then
  gum style --foreground 213 --bold "🔖 Committing and tagging..."
  
  # Check if there are changes to commit
  if ! git diff --quiet || ! git diff --cached --quiet; then
    if git add .; then
      gum style --foreground 213 "✅ Files added to git staging"
    else
      gum style --foreground 196 --bold "❌ Failed to add files to git staging"
      exit 1
    fi
    
    # Commit changes
    if git commit -m "release/$flavor/$version"; then
      gum style --foreground 213 "✅ Changes committed successfully"
    else
      gum style --foreground 196 --bold "❌ Failed to commit changes"
      echo ""
      echo "🔍 Possible causes:"
      echo "  • No changes to commit"
      echo "  • Git configuration issues"
      echo "  • File permission issues"
      exit 1
    fi
  else
    gum style --foreground 220 "⚠️ No changes to commit"
  fi
  
  # Create and push tag
  if git tag "release/$flavor/$version" -f; then
    gum style --foreground 213 "✅ Tag created: release/$flavor/$version"
    
    # Push tag to remote (optional)
    push_to_remote=$(gum choose --header="Push tag to remote repository?" yes no)
    if [ "$push_to_remote" == "yes" ]; then
      if git push origin "release/$flavor/$version" --force; then
        gum style --foreground 213 "✅ Tag pushed to remote: release/$flavor/$version"
      else
        gum style --foreground 196 --bold "❌ Failed to push tag to remote"
        echo ""
        echo "🔍 Tag was created locally but could not be pushed"
        echo "💡 You can push it manually later: git push origin release/$flavor/$version"
      fi
    fi
  else
    gum style --foreground 196 --bold "❌ Failed to create git tag"
    echo ""
    echo "🔍 Possible causes:"
    echo "  • Tag already exists and cannot be overwritten"
    echo "  • Git repository issues"
    echo "  • Permission issues"
    exit 1
  fi
fi

# === Build Summary ===
echo ""
gum style --foreground 82 --bold "🎉 Build completed successfully!"
echo ""

gum style --foreground 135 --bold "📦 Build Summary"
gum style --foreground 135 "   📁 $distribution_name"

# Show built files with sizes
files_built=false
if [ "$build_android" == "yes" ]; then
  if [ -f "$distribution_path/${file_name}.apk" ]; then
    apk_size=$(ls -lh "$distribution_path/${file_name}.apk" | awk '{print $5}')
    gum style --foreground 46 "   🤖 APK: $apk_size"
    files_built=true
  fi
  
  if [ "$flavor" == "prd" ] && [ -f "$distribution_path/${file_name}.aab" ]; then
    aab_size=$(ls -lh "$distribution_path/${file_name}.aab" | awk '{print $5}')
    gum style --foreground 220 "   📦 AAB: $aab_size"
    files_built=true
  fi
fi

if [ "$build_ios" == "yes" ] && [ -f "$distribution_path/${file_name}.ipa" ]; then
  ipa_size=$(ls -lh "$distribution_path/${file_name}.ipa" | awk '{print $5}')
  gum style --foreground 51 "   🍏 IPA: $ipa_size"
  files_built=true
fi

# Open distribution folder
if [ "$files_built" = true ]; then
  echo ""
  gum style --foreground 135 "🚀 Opening distribution folder..."
  open "$distribution_path"
fi
