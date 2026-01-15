#!/usr/bin/env python3
"""
Script to convert ARB file to CSV format for localization management

DESCRIPTION:
This script converts Flutter ARB (Application Resource Bundle) files to CSV format
for easier localization management. It automatically scans the ARB file to discover
prefix patterns and generates a config.json file for feature categorization.

NEW FEATURES:
- Automatic prefix detection from ARB file
- Auto-generation of config.json with discovered patterns
- Smart categorization based on actual key patterns in the project

USAGE:
    # Basic usage (auto-generates config.json, outputs to scripts/csv/intl_localization.csv)
    python3 scripts/csv/create_localization_csv.py
    
    # Custom input/output paths
    python3 scripts/csv/create_localization_csv.py assets/l10n/intl_en.arb output.csv
    
    # With existing custom feature mapping configuration
    python3 scripts/csv/create_localization_csv.py assets/l10n/intl_en.arb output.csv config.json
    
    # From project root directory
    cd /path/to/flutter/project
    python3 scripts/csv/create_localization_csv.py

REQUIREMENTS:
    - Python 3.6+
    - Input ARB file must be valid JSON format
    - Script must be run from project root directory

OUTPUT:
    - CSV file with columns: Feature, Description, Identifier, EN, TC, SC, Confirmed, Remark
    - EN column contains original ARB content (preserves formatting)
    - TC and SC columns are empty for translation input
    - Feature column auto-categorized based on discovered key prefixes
    - config.json file with discovered patterns (if not exists)

EXAMPLES:
    # Convert default ARB file (auto-generates config.json)
    python3 scripts/csv/create_localization_csv.py
    
    # Convert specific ARB file
    python3 scripts/csv/create_localization_csv.py assets/l10n/intl_zh.arb chinese_translations.csv
    
    # Convert with existing custom feature mapping
    python3 scripts/csv/create_localization_csv.py assets/l10n/intl_en.arb output.csv scripts/csv/config.json
    
    # Convert and specify custom output
    python3 scripts/csv/create_localization_csv.py assets/l10n/intl_en.arb translations/en_translations.csv

NOTES:
    - Original content formatting is preserved (quotes, placeholders, etc.)
    - Feature categorization is based on discovered key prefixes
    - Script automatically handles @@locale entries
    - Output CSV is UTF-8 encoded for international characters
    - Config file is auto-generated if not exists
"""

import json
import csv
import sys
import os
from pathlib import Path
from collections import defaultdict, Counter

def load_feature_config(config_file_path=None):
    """
    Load custom feature mapping configuration
    
    Args:
        config_file_path (str): Path to custom config file
        
    Returns:
        dict: Custom feature patterns or None if not found
    """
    if config_file_path and os.path.exists(config_file_path):
        try:
            with open(config_file_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
                return config.get('feature_patterns', {})
        except Exception as e:
            print(f"⚠️  Warning: Could not load config file {config_file_path}: {e}")
    
    return None

def scan_modules_directory(modules_dir='lib/src/modules'):
    """
    Scan modules directory to discover actual modules in the codebase
    
    Args:
        modules_dir (str): Path to modules directory
        
    Returns:
        list: List of discovered module names
    """
    discovered_modules = []
    
    if not os.path.exists(modules_dir):
        print(f"⚠️  Warning: Modules directory not found: {modules_dir}")
        return discovered_modules
    
    try:
        # Get all directories in modules folder
        for item in os.listdir(modules_dir):
            item_path = os.path.join(modules_dir, item)
            if os.path.isdir(item_path) and not item.startswith('.'):
                discovered_modules.append(item)
        
        # Sort modules alphabetically
        discovered_modules.sort()
        
        print(f"🔍 Discovered {len(discovered_modules)} modules: {', '.join(discovered_modules)}")
        
    except Exception as e:
        print(f"⚠️  Warning: Could not scan modules directory: {e}")
    
    return discovered_modules

def discover_prefixes_from_arb(arb_file_path, modules_list=None):
    """
    Scan ARB file to discover common prefixes and generate feature categories
    
    Args:
        arb_file_path (str): Path to the ARB file
        
    Returns:
        dict: Dictionary mapping prefixes to feature categories
    """
    try:
        with open(arb_file_path, 'r', encoding='utf-8') as f:
            arb_data = json.load(f)
        
        # Count prefix occurrences with smart grouping
        prefix_counts = defaultdict(int)
        prefix_examples = defaultdict(list)
        
        for key in arb_data.keys():
            if key == '@@locale':
                continue
                
            # Find prefixes (parts before underscore)
            if '_' in key:
                parts = key.split('_')
                # Check different prefix lengths (1, 2, 3, 4 parts)
                for i in range(1, min(5, len(parts))):
                    prefix = '_'.join(parts[:i]) + '_'
                    prefix_counts[prefix] += 1
                    if len(prefix_examples[prefix]) < 3:  # Keep examples
                        prefix_examples[prefix].append(key)
        
        # Smart prefix grouping - prioritize modules and longer, more specific prefixes
        feature_patterns = {}
        used_keys = set()
        
        # First, prioritize actual modules from codebase
        if modules_list:
            for module in modules_list:
                module_prefix = module + '_'
                if module_prefix in prefix_counts and prefix_counts[module_prefix] >= 2:
                    feature_patterns[module_prefix] = module
                    print(f"✅ Using actual module: {module}")
        
        # Sort by length (descending) then by count (descending) to prioritize specific prefixes
        sorted_prefixes = sorted(prefix_counts.items(), key=lambda x: (len(x[0]), x[1]), reverse=True)
        
        for prefix, count in sorted_prefixes:
            if count >= 2:  # Only include prefixes used at least twice
                # Skip if already added as module
                if prefix in feature_patterns:
                    continue
                    
                # Check if this prefix conflicts with already used keys
                prefix_without_underscore = prefix.rstrip('_')
                conflicting = False
                
                for used_prefix in feature_patterns.keys():
                    used_without_underscore = used_prefix.rstrip('_')
                    # If current prefix is a subset of used prefix, skip it
                    if prefix_without_underscore.startswith(used_without_underscore + '_'):
                        conflicting = True
                        break
                
                if not conflicting:
                    # Convert prefix to feature name
                    feature_name = prefix.rstrip('_').replace('_', ' ').title().replace(' ', '_').lower()
                    feature_patterns[prefix] = feature_name
        
        print(f"🔍 Discovered {len(feature_patterns)} prefix patterns...")
        
        return feature_patterns
        
    except Exception as e:
        print(f"⚠️  Warning: Could not analyze prefixes from {arb_file_path}: {e}")
        return {}

def generate_config_file(prefixes_dict, config_file_path='scripts/csv/config.json', arb_file_path='assets/l10n/intl_en.arb'):
    """
    Generate or update config.json file with discovered prefixes
    
    Args:
        prefixes_dict (dict): Dictionary mapping prefixes to feature categories
        config_file_path (str): Path where to save the config file
        arb_file_path (str): Path to the ARB file for version tracking
    """
    try:
        # Check if config file exists and get current version
        current_version = "1.0"
        existing_patterns = {}
        
        if os.path.exists(config_file_path):
            try:
                with open(config_file_path, 'r', encoding='utf-8') as f:
                    existing_config = json.load(f)
                    current_version = existing_config.get('version', '1.0')
                    existing_patterns = existing_config.get('feature_patterns', {})
            except Exception as e:
                print(f"⚠️  Warning: Could not read existing config: {e}")
        
        # Check if patterns have changed
        patterns_changed = existing_patterns != prefixes_dict
        
        # Increment version if patterns changed
        if patterns_changed:
            try:
                version_parts = current_version.split('.')
                major = int(version_parts[0])
                minor = int(version_parts[1]) if len(version_parts) > 1 else 0
                new_version = f"{major}.{minor + 1}"
            except:
                new_version = "1.1"
        else:
            new_version = current_version
        
        # Get ARB file modification time for tracking
        arb_mtime = ""
        if os.path.exists(arb_file_path):
            arb_mtime = os.path.getmtime(arb_file_path)
            arb_mtime = f"{arb_mtime:.0f}"
        
        # Create config structure
        config = {
            "description": "Auto-generated feature mapping configuration for ARB to CSV converter",
            "version": new_version,
            "generated_from": arb_file_path,
            "last_updated": arb_mtime,
            "patterns_changed": patterns_changed,
            "feature_patterns": prefixes_dict,
            "notes": [
                "This configuration file was automatically generated by analyzing the ARB file.",
                "The patterns are based on actual key prefixes found in your localization files.",
                "You can manually edit this file to customize feature categorization.",
                "Patterns use prefix matching (key.startswith(pattern)), so include the underscore if needed.",
                "If no pattern matches, the script will fall back to generic categorization.",
                f"Version {new_version} - {'Updated' if patterns_changed else 'No changes detected'} from ARB analysis."
            ]
        }
        
        # Ensure directory exists
        os.makedirs(os.path.dirname(config_file_path), exist_ok=True)
        
        # Write config file
        with open(config_file_path, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2, ensure_ascii=False)
        
        if patterns_changed:
            print(f"✅ Updated config file: {config_file_path}")
            print(f"📊 Version: {current_version} → {new_version}")
            print(f"📊 Contains {len(prefixes_dict)} feature patterns")
            
            # Show what changed
            added_patterns = set(prefixes_dict.keys()) - set(existing_patterns.keys())
            removed_patterns = set(existing_patterns.keys()) - set(prefixes_dict.keys())
            
            if added_patterns:
                print(f"➕ Added patterns: {', '.join(sorted(added_patterns)[:5])}")
                if len(added_patterns) > 5:
                    print(f"   ... and {len(added_patterns) - 5} more")
            
            if removed_patterns:
                print(f"➖ Removed patterns: {', '.join(sorted(removed_patterns)[:5])}")
                if len(removed_patterns) > 5:
                    print(f"   ... and {len(removed_patterns) - 5} more")
        else:
            print(f"✅ Config file unchanged: {config_file_path}")
            print(f"📊 Version: {new_version} (no changes detected)")
        
    except Exception as e:
        print(f"⚠️  Warning: Could not generate config file {config_file_path}: {e}")

def check_and_update_config(arb_file_path, config_file_path='scripts/csv/config.json'):
    """
    Check if config needs updating and update if necessary
    
    Args:
        arb_file_path (str): Path to the ARB file
        config_file_path (str): Path to config file
        
    Returns:
        dict: Feature patterns configuration
    """
    # Scan modules directory first
    modules_list = scan_modules_directory()
    
    # Always analyze current ARB file to get latest patterns
    print(f"🔍 Analyzing ARB file for current patterns...")
    current_prefixes = discover_prefixes_from_arb(arb_file_path, modules_list)
    
    if not current_prefixes:
        print(f"⚠️  Warning: Could not discover prefixes. Using fallback patterns.")
        return {}
    
    # Generate/update config file with current patterns
    generate_config_file(current_prefixes, config_file_path, arb_file_path)
    
    return current_prefixes

def load_or_generate_config(arb_file_path, config_file_path=None):
    """
    Load existing config or generate new one based on ARB file analysis
    
    Args:
        arb_file_path (str): Path to the ARB file
        config_file_path (str): Path to config file (optional)
        
    Returns:
        dict: Feature patterns configuration
    """
    # Default config path
    if not config_file_path:
        config_file_path = 'scripts/csv/config.json'
    
    # Always check and update config to ensure it's current
    return check_and_update_config(arb_file_path, config_file_path)

def scan_localization_files(l10n_dir='assets/l10n'):
    """
    Scan l10n directory for ARB files and extract locale information
    
    Args:
        l10n_dir (str): Path to l10n directory
        
    Returns:
        tuple: (locales_dict, available_files)
            - locales_dict: {locale: file_path} mapping
            - available_files: list of ARB files found
    """
    locales_dict = {}
    available_files = []
    
    if not os.path.exists(l10n_dir):
        return locales_dict, available_files
    
    # Find all ARB files
    for file in os.listdir(l10n_dir):
        if file.endswith('.arb'):
            file_path = os.path.join(l10n_dir, file)
            available_files.append(file_path)
            
            # Extract locale from file
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    arb_data = json.load(f)
                    locale = arb_data.get('@@locale', 'unknown')
                    locales_dict[locale] = file_path
            except Exception as e:
                print(f"⚠️  Warning: Could not read locale from {file_path}: {e}")
                # Try to extract locale from filename
                filename_locale = file.replace('intl_', '').replace('.arb', '')
                locales_dict[filename_locale] = file_path
    
    return locales_dict, available_files

def create_csv_from_arb(arb_file_path, output_csv_path, custom_config=None, locales_dict=None):
    """
    Convert ARB file to CSV format with original content preserved
    
    Args:
        arb_file_path (str): Path to the input ARB file
        output_csv_path (str): Path to the output CSV file
        custom_config (dict): Custom feature patterns configuration
        locales_dict (dict): Dictionary mapping locales to file paths
    """
    
    try:
        # Read ARB file
        with open(arb_file_path, 'r', encoding='utf-8') as f:
            arb_data = json.load(f)
        
        print(f"✅ Loaded ARB file: {arb_file_path}")
        print(f"📊 Found {len(arb_data)} entries")
        
        # Determine available locales and create dynamic columns
        if locales_dict:
            # Sort locales for consistent column order
            sorted_locales = sorted(locales_dict.keys())
            print(f"🌍 Found locales: {', '.join(sorted_locales)}")
        else:
            # Fallback to default locales
            sorted_locales = ['en', 'zh_Hant', 'zh_Hans']
            print(f"🌍 Using default locales: {', '.join(sorted_locales)}")
        
        # Create CSV with original content
        with open(output_csv_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            
            # Dynamic header based on available locales
            header = ['Feature', 'Description', 'Identifier'] + sorted_locales + ['Confirmed', 'Remark']
            writer.writerow(header)
            
            # Locale row with actual locale values
            locale_row = ['', '', '@@locale'] + sorted_locales + ['', '']
            writer.writerow(locale_row)
            
            # Load all locale data for comparison
            all_locale_data = {}
            for locale, file_path in locales_dict.items():
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        all_locale_data[locale] = json.load(f)
                except Exception as e:
                    print(f"⚠️  Warning: Could not load {file_path}: {e}")
                    all_locale_data[locale] = {}
            
            # Data rows - collect all rows first for sorting
            all_rows = []
            for key, value in arb_data.items():
                if key == '@@locale':
                    continue
                    
                # Determine feature from key (with custom config if provided)
                feature = determine_feature(key, custom_config)
                
                # Description from key - remove prefix if it matches feature
                description = key.replace('_', ' ').lower()
                
                # Remove feature prefix from description to avoid redundancy
                if feature != 'common' and key.startswith(feature + '_'):
                    # Remove the feature prefix from description
                    description = description.replace(feature + ' ', '', 1)
                elif '_' in key:
                    # For other cases, try to remove the first part if it matches common patterns
                    first_part = key.split('_')[0]
                    if description.startswith(first_part + ' '):
                        description = description.replace(first_part + ' ', '', 1)
                
                # Create row with content from all locales
                row = [feature, description, key]
                
                # Add content for each locale
                for locale in sorted_locales:
                    if locale in all_locale_data and key in all_locale_data[locale]:
                        locale_content = str(all_locale_data[locale][key])
                    else:
                        locale_content = ''  # Empty if key doesn't exist in this locale
                    row.append(locale_content)
                
                # Add confirmed and remark columns
                row.extend(['Pending', ''])
                
                all_rows.append(row)
            
            # Sort rows by feature, then by description
            all_rows.sort(key=lambda x: (x[0], x[1]))
            
            # Write sorted rows
            for row in all_rows:
                writer.writerow(row)
        
        print(f"✅ CSV file created successfully: {output_csv_path}")
        print(f"📊 Rows sorted by feature category, then by description")
        
        # Count rows and show feature distribution
        with open(output_csv_path, 'r', encoding='utf-8') as f:
            row_count = sum(1 for line in f)
        
        print(f"📊 CSV contains {row_count} rows (including header)")
        print(f"📊 Data rows: {row_count - 1}")
        
        # Show feature distribution
        feature_counts = {}
        for row in all_rows:
            feature = row[0]
            feature_counts[feature] = feature_counts.get(feature, 0) + 1
        
        print(f"📊 Feature distribution:")
        for feature, count in sorted(feature_counts.items()):
            print(f"   {feature}: {count} keys")
        
    except FileNotFoundError:
        print(f"❌ Error: ARB file not found: {arb_file_path}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Error: Invalid JSON in ARB file: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

def determine_feature(key, custom_config=None):
    """
    Determine feature category from key name using configurable mapping
    
    This function uses a flexible approach to categorize keys:
    1. First tries custom config patterns (if provided)
    2. Then tries universal Flutter patterns
    3. Falls back to generic categorization
    4. Can be easily customized for different projects
    
    Args:
        key (str): The localization key
        custom_config (dict): Custom feature patterns from config file
        
    Returns:
        str: Feature category
    """
    
    # Custom patterns from config file (highest priority)
    if custom_config:
        for pattern, feature in custom_config.items():
            if key.startswith(pattern):
                return feature
    
    # Common Flutter/Android/iOS patterns (universal fallback)
    universal_patterns = {
        'auth_': 'auth',
        'login_': 'auth', 
        'logout_': 'auth',
        'signup_': 'auth',
        'register_': 'auth',
        'reset_': 'auth',
        'password_': 'auth',
        'otp_': 'auth',
        'verification_': 'auth',
        
        'common_': 'common',
        'general_': 'common',
        'ui_': 'common',
        'button_': 'common',
        'label_': 'common',
        'hint_': 'common',
        'error_': 'common',
        'success_': 'common',
        'warning_': 'common',
        'info_': 'common',
        
        'validation_': 'validation',
        'validate_': 'validation',
        'invalid_': 'validation',
        
        'settings_': 'settings',
        'preference_': 'settings',
        'config_': 'settings',
        'profile_': 'settings',
        'account_': 'settings',
        
        'dashboard_': 'dashboard',
        'home_': 'dashboard',
        'main_': 'dashboard',
        
        'notification_': 'notification',
        'alert_': 'notification',
        'message_': 'notification',
        
        'payment_': 'payment',
        'billing_': 'payment',
        'checkout_': 'payment',
        'order_': 'payment',
        
        'booking_': 'booking',
        'reservation_': 'booking',
        'appointment_': 'booking',
        
        'search_': 'search',
        'filter_': 'search',
        
        'help_': 'help',
        'support_': 'help',
        'faq_': 'help',
        
        'about_': 'about',
        'info_': 'about',
        
        'privacy_': 'legal',
        'terms_': 'legal',
        'policy_': 'legal',
        'legal_': 'legal',
        
        'onboarding_': 'onboarding',
        'tutorial_': 'onboarding',
        'intro_': 'onboarding',
        'welcome_': 'onboarding',
        
        'force_update_': 'update',
        'update_': 'update',
        'version_': 'update',
        
        'pdf_': 'document',
        'file_': 'document',
        'download_': 'document',
        'upload_': 'document',
    }
    
    # Check for universal patterns
    for prefix, feature in universal_patterns.items():
        if key.startswith(prefix):
            return feature
    
    # Generic categorization based on key structure
    if '_' in key:
        # Extract the first part before underscore
        first_part = key.split('_')[0]
        
        # Common first parts
        generic_mapping = {
            'app': 'app',
            'main': 'main',
            'home': 'home',
            'menu': 'menu',
            'tab': 'tab',
            'page': 'page',
            'screen': 'screen',
            'view': 'view',
            'widget': 'widget',
            'component': 'component',
            'dialog': 'dialog',
            'modal': 'modal',
            'popup': 'popup',
            'toast': 'toast',
            'snackbar': 'toast',
            'loading': 'loading',
            'progress': 'loading',
            'spinner': 'loading',
            'empty': 'empty',
            'placeholder': 'placeholder',
            'default': 'default',
            'fallback': 'fallback',
        }
        
        if first_part in generic_mapping:
            return generic_mapping[first_part]
    
    # Default fallback
    return 'common'

def main():
    """
    Main function - Entry point for the script
    
    This function handles command line arguments and orchestrates the conversion process.
    It provides helpful error messages and usage instructions if something goes wrong.
    
    Command line arguments:
        [0] script name
        [1] ARB file path (optional)
        [2] CSV output path (optional) 
        [3] Config file path (optional)
    """
    
    # Default paths (relative to project root)
    arb_file = 'assets/l10n/intl_en.arb'
    csv_file = 'scripts/csv/intl_localization.csv'
    config_file = None
    
    # Parse command line arguments
    if len(sys.argv) >= 2:
        arb_file = sys.argv[1]
    if len(sys.argv) >= 3:
        csv_file = sys.argv[2]
    if len(sys.argv) >= 4:
        config_file = sys.argv[3]
    
    # Load or generate configuration
    if config_file:
        custom_config = load_feature_config(config_file)
    else:
        custom_config = load_or_generate_config(arb_file)
    
    # Scan for available localization files
    locales_dict, available_files = scan_localization_files()
    
    # Check if ARB file exists
    if not os.path.exists(arb_file):
        print(f"❌ Error: ARB file not found: {arb_file}")
        print(f"💡 Usage: python3 {sys.argv[0]} [arb_file] [csv_file] [config_file]")
        print(f"💡 Example: python3 {sys.argv[0]} assets/l10n/intl_en.arb output.csv")
        print(f"💡 With config: python3 {sys.argv[0]} assets/l10n/intl_en.arb output.csv config.json")
        print(f"💡 Make sure you're running from the project root directory")
        print(f"💡 Available ARB files:")
        
        if available_files:
            for file_path in sorted(available_files):
                print(f"   - {file_path}")
        else:
            print(f"   No ARB files found in assets/l10n/")
        
        sys.exit(1)
    
    print(f"🚀 Converting ARB to CSV...")
    print(f"📁 Input: {arb_file}")
    print(f"📁 Output: {csv_file}")
    if config_file:
        print(f"📁 Config: {config_file}")
    print()
    
    # Create CSV
    create_csv_from_arb(arb_file, csv_file, custom_config, locales_dict)
    
    print()
    print("🎉 Conversion completed successfully!")
    print("💡 Next steps:")
    print("   - Review translations in all locale columns")
    print("   - Fill in missing translations for each locale")
    print("   - Use a CSV editor (Excel, Google Sheets, etc.) for easier editing")
    print("   - Import back to ARB format when translations are complete")
    print("   - Consider creating a reverse script to convert CSV back to ARB")
    print()
    print("🔧 Configuration:")
    if config_file:
        print(f"   - Used existing config file: {config_file}")
    else:
        print(f"   - Generated new config file: scripts/csv/config.json")
        print(f"   - You can edit this file to customize feature categorization")

if __name__ == "__main__":
    main()
