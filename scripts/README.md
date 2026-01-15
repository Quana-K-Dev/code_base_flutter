# Scripts Directory

This directory contains utility scripts for the Flutter project.

## 📁 Directory Structure

```
scripts/
├── csv/                           # CSV conversion utilities
│   ├── create_localization_csv.py # ARB to CSV converter
│   ├── localization_config.json   # Feature mapping configuration
│   └── README_localization_csv.md # CSV tools documentation
├── clean.sh                       # Clean build artifacts
├── export_development.plist      # Development export configuration
├── export.plist                  # Production export configuration
├── flutterfire_validator.sh      # Firebase configuration validator
├── flutterfire.sh                # Firebase setup script
├── frx_cleanup.dart              # Riverpod code generation cleanup
├── generate_assets.sh            # Asset generation script
├── mag_validator.sh              # Magnificent app validator
├── release.sh                    # Release build script
├── tf.sh                         # Terraform deployment script
├── webp.sh                       # WebP image conversion script
└── yq_validator.sh               # YAML validator script
```

## 🛠️ Available Scripts

### CSV Conversion Tools

**Location**: `scripts/csv/`

- **`create_localization_csv.py`**: Converts Flutter ARB files to CSV format for easier localization management
- **`localization_config.json`**: Configuration file for customizing feature mapping
- **`README_localization_csv.md`**: Detailed documentation for CSV tools

**Quick Start**:
```bash
python3 scripts/csv/create_localization_csv.py
```

### Build & Deployment Scripts

- **`clean.sh`**: Clean build artifacts and temporary files
- **`release.sh`**: Build release version of the app
- **`export.plist`**: Production export configuration
- **`export_development.plist`**: Development export configuration

### Firebase Scripts

- **`flutterfire.sh`**: Setup Firebase configuration
- **`flutterfire_validator.sh`**: Validate Firebase configuration

### Asset Management

- **`generate_assets.sh`**: Generate app assets
- **`webp.sh`**: Convert images to WebP format

### Code Generation

- **`frx_cleanup.dart`**: Cleanup Riverpod code generation artifacts

### Validation Scripts

- **`mag_validator.sh`**: Validate Magnificent app configuration
- **`yq_validator.sh`**: Validate YAML files

### Infrastructure

- **`tf.sh`**: Terraform deployment script

## 🚀 Usage Examples

### Localization Management
```bash
# Convert ARB to CSV
python3 scripts/csv/create_localization_csv.py

# Convert with custom config
python3 scripts/csv/create_localization_csv.py assets/l10n/intl_en.arb output.csv scripts/csv/localization_config.json
```

### Build Process
```bash
# Clean build artifacts
./scripts/clean.sh

# Build release
./scripts/release.sh
```

### Firebase Setup
```bash
# Setup Firebase
./scripts/flutterfire.sh

# Validate Firebase config
./scripts/flutterfire_validator.sh
```

### Asset Generation
```bash
# Generate assets
./scripts/generate_assets.sh

# Convert images to WebP
./scripts/webp.sh
```

## 📋 Requirements

- **Python 3.6+** (for CSV conversion scripts)
- **Flutter SDK** (for Flutter-related scripts)
- **Bash** (for shell scripts)
- **Dart SDK** (for Dart scripts)

## 🔧 Configuration

### CSV Conversion Configuration

Create custom feature mapping by modifying `scripts/csv/localization_config.json`:

```json
{
  "feature_patterns": {
    "auth_": "authentication",
    "common_": "common_ui",
    "custom_pattern_": "custom_feature"
  }
}
```

### Build Configuration

Modify export plist files for different build configurations:
- `export_development.plist`: Development builds
- `export.plist`: Production builds

## 📚 Documentation

- **CSV Tools**: See `scripts/csv/README_localization_csv.md` for detailed documentation
- **Individual Scripts**: Each script contains inline documentation and usage examples

## 🤝 Contributing

When adding new scripts:

1. Place them in the appropriate subdirectory
2. Add documentation and usage examples
3. Update this README with script description
4. Ensure scripts are executable (`chmod +x script_name`)
5. Test scripts thoroughly before committing

## 📄 License

These scripts are part of the Flutter project and follow the project's license terms.
