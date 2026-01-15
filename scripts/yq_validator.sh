#!/bin/bash
# Check if mag command exists
command -v yq &> /dev/null

if [ $? -eq 0 ]; then
  GREEN='\033[0;32m'
  NC='\033[0m' # No Color
  echo "${GREEN}yq is already installed.${NC}"
else
  echo -w "warning: yq not found. Installing..."

  # Install the yq (assuming you have pub installed)
  brew install yq

  if [ $? -eq 0 ]; then
    echo "yq installation successful!"
  else
    echo "error: Error installing yq. Please check your internet connection and try again."
  fi
fi
