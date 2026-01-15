#!/bin/bash

# Check if mag command exists
command -v mag &> /dev/null

if [ $? -eq 0 ]; then
  GREEN='\033[0;32m'
  NC='\033[0m' # No Color
  echo "${GREEN}magical_version_bump is already installed.${NC}"
else
  echo "warning: magical_version_bump not found. Installing..."

  # Install the magical_version_bump (assuming you have pub installed)
  dart pub global activate magical_version_bump

  if [ $? -eq 0 ]; then
    echo "magical_version_bump installation successful!"
  else
    echo "error: Error installing magical_version_bump. Please check your internet connection and try again."
  fi
fi
