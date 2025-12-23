# Changelog

All notable changes to this project will be documented in this file.

## [0.0.1] - 2024-11-18

### Added
- Initial release of Feeddo Flutter SDK
- `FeeddoClient` class for interacting with Feeddo API
- `EndUser` model for managing end user data
- `upsertEndUser()` method for creating/updating users
- `initializeUser()` convenience method for user session initialization
- `updateUser()` method for updating existing users
- Automatic device information collection:
  - Platform detection (iOS, Android, Web, Desktop)
  - Device model information
  - OS version
  - App version from package info
  - Locale and country code detection
- `DeviceInfoHelper` utility for cross-platform device info
- `ApiService` for HTTP communication with Feeddo backend
- `FeeddoApiException` for error handling
- User ID caching for seamless experience
- Custom attributes support for user segmentation
- Comprehensive example app demonstrating all features
- Full documentation and API reference

### Dependencies
- http: ^1.2.0
- device_info_plus: ^10.1.0
- package_info_plus: ^8.0.0

### Platform Support
- ✅ iOS
- ✅ Android
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

