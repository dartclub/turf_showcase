# API documentation for turf-dart and geotypes written in flutter

# Installation
## Locally (For Development)
###  Requirements
- Chrome
- Flutter cli

If you are using bash you can run our script
`./scripts/develop_chrome.sh`

Otherwise you can run
```
flutter doctor -v # to check if you have all dependencies
flutter pub get
flutter run -d chrome
```

## Static site
### Requirement
- git

The GitHub pages site will be rebuilt on a push action to the main branch. In
order to do this you can create a Pull Request and merge it into master to
initiate a build.
