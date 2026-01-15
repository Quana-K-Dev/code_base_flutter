#######################################################################
# ENVIRONMENT CONFIGURATION - MASTER EXAMPLE FILE
#
# This file is a TEMPLATE and DOCUMENTATION for all environments.
# Copy this file and rename it to one of the following:
#
#   .env.dev    -> Development environment
#   .env.alpha  -> Alpha / Prototype environment
#   .env.uat    -> User Acceptance Testing environment
#   .
#   .env.prd    -> Production environment
#
# Then adjust values according to the target environment.
#
# IMPORTANT:
# - Do NOT commit real environment files (.env.dev, .env.prd, ...)
# - This example file must NEVER contain secrets or real credentials.
#
#######################################################################


FOR EXAMPE:
#######################################################################
# ENVIRONMENT: DEVELOPMENT (DEV)
#
# Purpose:
# - Used for daily development and feature implementation.
# - Enables debugging, verbose logs, hot reload.
#
# Characteristics:
# - Connects to DEV backend.
# - Data may be reset at any time.
# - App name usually includes [DEV] prefix.
#
#######################################################################
# --- App Info ---
FLAVOR=DEV                              # Environment name (DEV / UAT / PRD)
PACKAGE_NAME=your.bundle.id             # Android applicationId
BUNDLE_ID=your.package.name             # iOS bundle identifier
APPLE_TEAM_ID=APPLETEAMID               # Apple Developer Team ID
APP_NAME=[DEV]YourAppName               # App display name (shown on device)

# --- Backend Config ---
API_URL="https://example.tld/api/v1"    # Backend API URL for this environment


#######################################################################
#
#    Run app with:
#    flutter run --flavor dev --dart-define-from-file=env/.env.dev
#
#######################################################################
