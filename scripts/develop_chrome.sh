#!/bin/bash
# Bash commands to launch development in chrome browser

# Check dependencies
if $(flutter --version) != 0; then
  echo "flutter is not installed"
  exit 1
fi

# Output doctor for debug
flutter doctor -v
# pub get
flutter pub get
# build
flutter build web
