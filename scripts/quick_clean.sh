#!/bin/bash

# Prompt the user for a relative path
read -p "Enter the relative path: " relative_path

# Extract the directory path
directory_path=$(dirname "$relative_path")

# Run the dart command with the directory path
dart run build_runner build --delete-conflicting-outputs --build-filter="$directory_path/**"