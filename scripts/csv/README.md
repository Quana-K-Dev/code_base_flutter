# ARB to CSV Converter Script

This script converts Flutter ARB (Application Resource Bundle) files to CSV format for easier localization management. It features **automatic module detection**, **smart prefix grouping**, and **intelligent feature categorization** based on your actual codebase structure.

## 📋 Description

The script preserves original content formatting and creates a structured CSV that can be used for translation workflows. It automatically scans your `lib/src/modules/` directory to discover actual modules and uses them for feature categorization. The script also intelligently groups prefixes and removes redundancy from descriptions, making the CSV output clean and professional.

## 🚀 Quick Start

```bash
# From project root directory (auto-generates config.json)
python3 scripts/csv/create_localization_csv.py
```

## 📖 Usage

### Basic Usage
```bash
# Uses default paths: assets/l10n/intl_en.arb -> scripts/csv/intl_localization.csv
# Automatically scans modules and generates config.json
python3 scripts/csv/create_localization_csv.py
```

### Custom Paths
```bash
# Specify input and output files
python3 scripts/csv/create_localization_csv.py assets/l10n/intl_zh.arb chinese_translations.csv
```

### With Existing Configuration
```bash
# Use existing custom feature mapping configuration
python3 scripts/csv/create_localization_csv.py assets/l10n/intl_en.arb output.csv scripts/csv/config.json
```

### Examples
```bash
# Convert English ARB file (auto-generates config)
python3 scripts/csv/create_localization_csv.py assets/l10n/intl_en.arb en_translations.csv

# Convert Chinese ARB file
python3 scripts/csv/create_localization_csv.py assets/l10n/intl_zh.arb zh_translations.csv

# Convert with existing custom feature mapping
python3 scripts/csv/create_localization_csv.py assets/l10n/intl_en.arb output.csv scripts/csv/config.json

# Convert with custom output location
python3 scripts/csv/create_localization_csv.py assets/l10n/intl_en.arb translations/en_localization.csv
```

## 📊 Output Format

The script creates a CSV file with the following columns:

| Column | Description | Example |
|--------|-------------|---------|
| Feature | Auto-categorized feature | `auth`, `common`, `settings` |
| Description | Human-readable description | `login button`, `error message` |
| Identifier | Original ARB key | `auth_login_button`, `common_error` |
| EN | Original English content | `"Log In"`, `"Hello, {name}"` |
| TC | Traditional Chinese (empty) | _(to be filled)_ |
| SC | Simplified Chinese (empty) | _(to be filled)_ |
| Confirmed | Status | `Confirmed` |
| Remark | Notes | _(optional)_ |

## 🔧 Requirements

- **Python 3.6+**
- **Valid ARB file** (JSON format)
- **Project root directory** (script must be run from project root)

## 📁 File Structure

```
project/
├── scripts/
│   └── csv/
│       ├── create_localization_csv.py
│       ├── localization_config.json
│       └── README_localization_csv.md
├── assets/
│   └── l10n/
│       ├── intl_en.arb
│       └── intl_zh.arb
└── scripts/csv/intl_localization.csv (default output)
```

## ✨ Features

### 🎯 **Core Features**
- **Preserves formatting**: Quotes, placeholders, special characters
- **Auto-categorization**: Groups keys by feature prefixes
- **Smart sorting**: Rows sorted by feature category, then by description
- **UTF-8 support**: Handles international characters
- **Flexible input**: Custom input/output paths
- **Progress reporting**: Shows conversion progress and statistics

### 🧠 **Intelligent Features**
- **Module detection**: Automatically scans `lib/src/modules/` directory
- **Smart prefix grouping**: Prioritizes longer, more specific prefixes
- **Redundancy removal**: Removes feature prefix from descriptions
- **Version tracking**: Auto-increments config version when patterns change
- **Conflict resolution**: Prevents overlapping feature patterns

### ⚙️ **Configuration Features**
- **Auto-generation**: Creates `config.json` automatically if not exists
- **Configurable mapping**: Custom feature patterns via JSON config
- **Universal patterns**: Works with common Flutter/Android/iOS patterns
- **Change detection**: Updates config only when patterns change
- **Cross-project compatibility**: Reusable across different Flutter projects

## 🎯 Feature Categories

The script automatically categorizes keys using a **two-step intelligent process**:

### 1. **Module-Based Categorization** (Priority)
First, it scans your `lib/src/modules/` directory to discover actual modules:

| Module | Feature | Example Keys |
|--------|---------|--------------|
| `auth/` | `auth` | `auth_login_button`, `auth_forgot_password` |
| `booking/` | `booking` | `booking_form_step`, `booking_checkout` |
| `change_email/` | `change_email` | `change_email_title`, `change_email_success` |
| `change_name/` | `change_name` | `change_name_title`, `change_name_update` |
| `change_password/` | `change_password` | `change_password_title`, `change_password_success` |
| `settings/` | `settings` | `settings_account_title`, `settings_language` |
| `otp/` | `otp` | `otp_send_code`, `otp_verify` |
| `register/` | `register` | `register_title`, `register_success` |
| `reset/` | `reset` | `reset_password`, `reset_success` |

### 2. **Smart Prefix Grouping** (Fallback)
For keys not matching modules, it uses intelligent prefix grouping:

| Prefix | Feature | Example Keys |
|--------|---------|--------------|
| `common_` | `common` | `common_ok`, `common_cancel` |
| `dropdown_` | `dropdown` | `dropdown_date_label`, `dropdown_package` |
| `error_` | `error` | `error_network`, `error_invalid` |
| `my_bookings_` | `my_bookings` | `my_bookings_title`, `my_bookings_status` |
| `pdf_` | `pdf` | `pdf_viewer_download`, `pdf_error` |
| `force_update_` | `force_update` | `force_update_message`, `force_update_button` |

## ⚙️ Configuration

### 🔄 **Automatic Configuration Generation**

The script automatically generates `config.json` based on your actual codebase:

```bash
# First run - generates config.json automatically
python3 scripts/csv/create_localization_csv.py
```

**Generated config.json structure:**
```json
{
  "description": "Auto-generated feature mapping configuration for ARB to CSV converter",
  "version": "1.3",
  "generated_from": "assets/l10n/intl_en.arb",
  "last_updated": "1761584297",
  "patterns_changed": true,
  "feature_patterns": {
    "auth_": "auth",
    "booking_": "booking",
    "change_email_": "change_email",
    "change_name_": "change_name",
    "change_password_": "change_password",
    "settings_": "settings",
    "otp_": "otp",
    "register_": "register",
    "reset_": "reset"
  },
  "notes": [
    "This configuration file was automatically generated by analyzing the ARB file.",
    "The patterns are based on actual key prefixes found in your localization files.",
    "You can manually edit this file to customize feature categorization.",
    "Version 1.3 - Updated from ARB analysis."
  ]
}
```

### 📝 **Manual Configuration**

You can also create custom configurations:

```json
{
  "feature_patterns": {
    "auth_": "authentication",
    "common_": "common_ui",
    "custom_pattern_": "custom_feature"
  }
}
```

### 🔧 **Configuration Features**

- **Version tracking**: Auto-increments when patterns change
- **Change detection**: Only updates when necessary
- **Module priority**: Actual modules take precedence over generic patterns
- **Conflict resolution**: Prevents overlapping patterns
- **Backup support**: Preserves existing configs

## 🔄 Workflow

### 📋 **Standard Workflow**
1. **Run script**: `python3 scripts/csv/create_localization_csv.py`
2. **Auto-generation**: Script scans modules and generates `config.json`
3. **CSV creation**: Creates sorted CSV with feature categorization
4. **Edit translations**: Fill in TC and SC columns
5. **Review**: Check translations for accuracy
6. **Import back**: Convert CSV back to ARB format (separate script needed)

### 🔄 **Version Management**
- **First run**: Generates `config.json` with version `1.0`
- **Pattern changes**: Auto-increments version (e.g., `1.0` → `1.1`)
- **No changes**: Keeps same version, shows "no changes detected"
- **Manual edits**: Preserves your customizations

### 📊 **Output Information**
The script provides detailed feedback:
```
🔍 Discovered 25 modules: auth, booking, change_email, ...
✅ Using actual module: auth
✅ Using actual module: booking
🔍 Discovered 50 prefix patterns...
✅ Updated config file: scripts/csv/config.json
📊 Version: 1.2 → 1.3
📊 Contains 50 feature patterns
📊 Feature distribution:
   auth: 31 keys
   booking: 65 keys
   change_email: 7 keys
   ...
```

## 🚀 Advanced Usage

### Batch Processing

Process multiple ARB files:

```bash
# Process all ARB files in a directory
for file in assets/l10n/*.arb; do
    python3 scripts/csv/create_localization_csv.py "$file" "csv/$(basename "$file" .arb).csv"
done
```

### Integration with CI/CD

Add to your build pipeline:

```yaml
# GitHub Actions example
- name: Generate CSV from ARB
  run: |
    python3 scripts/csv/create_localization_csv.py assets/l10n/intl_en.arb translations/en.csv
    python3 scripts/csv/create_localization_csv.py assets/l10n/intl_zh.arb translations/zh.csv
```

### Custom Output Directory

```bash
# Create organized output structure
mkdir -p translations/csv
python3 scripts/csv/create_localization_csv.py assets/l10n/intl_en.arb translations/csv/en_localization.csv
```

### Project-Specific Configurations

Create different configs for different projects:

```bash
# E-commerce project
python3 scripts/csv/create_localization_csv.py assets/l10n/intl_en.arb output.csv configs/ecommerce_config.json

# Healthcare project  
python3 scripts/csv/create_localization_csv.py assets/l10n/intl_en.arb output.csv configs/healthcare_config.json
```

## 🚨 Troubleshooting

### Common Issues

**File not found error:**
```bash
❌ Error: ARB file not found: assets/l10n/intl_en.arb
💡 Make sure you're running from the project root directory
```

**Solution**: Run from project root directory where `assets/` folder exists.

**Invalid JSON error:**
```bash
❌ Error: Invalid JSON in ARB file: Expecting ',' delimiter
```

**Solution**: Check ARB file for syntax errors, missing commas, or quotes.

**Permission error:**
```bash
❌ Error: Permission denied
```

**Solution**: Make sure you have write permissions in the output directory.

## 📝 Key Improvements

### 🎯 **Smart Categorization**
- **Module-first approach**: Prioritizes actual modules from `lib/src/modules/`
- **Intelligent grouping**: Groups related prefixes (e.g., `change_email_`, `change_name_`)
- **Redundancy removal**: Removes feature prefix from descriptions
- **Conflict resolution**: Prevents overlapping patterns

### 📊 **Enhanced Output**
- **Sorted rows**: By feature category, then by description
- **Clean descriptions**: No redundant prefixes
- **Feature distribution**: Shows key count per feature
- **Version tracking**: Auto-increments config version

### 🔧 **Developer Experience**
- **Zero configuration**: Works out of the box
- **Auto-detection**: Scans your actual codebase structure
- **Change tracking**: Only updates when necessary
- **Detailed feedback**: Shows what's happening during execution

## 📝 Technical Notes

- Original content formatting is preserved (quotes, placeholders, etc.)
- Feature categorization aligns with your actual module structure
- Script automatically handles `@@locale` entries
- Output CSV is UTF-8 encoded for international characters
- Empty TC and SC columns are ready for translation input
- Config file is auto-generated and version-controlled

## 🤝 Contributing

To improve this script:
1. **Enhanced module detection**: Support for more complex module structures
2. **Reverse conversion**: Create CSV to ARB converter
3. **Translation validation**: Check for missing or incomplete translations
4. **Multi-language support**: Support for more languages
5. **Integration**: Connect with translation services (Google Translate, DeepL)
6. **UI improvements**: Better progress indicators and error messages
7. **Performance**: Optimize for large ARB files
8. **Testing**: Add comprehensive test suite

## 📄 License

This script is part of the Flutter project localization workflow.
