#!/bin/bash
# Bash commands to launch development in chrome browser

# Check dependencies
if ( flutter --version ) != 0 {
  echo "flutter is not installed"
  exit 1
}
# Output doctor for debug
flutter doctor -v
# pub get
flutter pub get
# run development image in chrome
flutter run -d chrome
