import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Helper class to collect device and package information
class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get comprehensive device and app information
  static Future<DeviceInfo> getDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();

    String platform = 'other';
    String? deviceModel;
    String? osVersion;

    if (kIsWeb) {
      platform = 'web';
      final webInfo = await _deviceInfo.webBrowserInfo;
      deviceModel = '${webInfo.browserName} ${webInfo.platform}';
      osVersion = webInfo.userAgent;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      platform = 'android';
      final androidInfo = await _deviceInfo.androidInfo;
      deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      osVersion =
          'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      platform = 'ios';
      final iosInfo = await _deviceInfo.iosInfo;
      deviceModel = iosInfo.model;
      osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      platform = 'desktop';
      final macInfo = await _deviceInfo.macOsInfo;
      deviceModel = 'macOS ${macInfo.model}';
      osVersion = macInfo.osRelease;
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      platform = 'desktop';
      final windowsInfo = await _deviceInfo.windowsInfo;
      deviceModel = 'Windows ${windowsInfo.computerName}';
      osVersion = windowsInfo.productName;
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      platform = 'desktop';
      final linuxInfo = await _deviceInfo.linuxInfo;
      deviceModel = 'Linux ${linuxInfo.name}';
      osVersion = linuxInfo.version;
    }

    return DeviceInfo(
      platform: platform,
      deviceModel: deviceModel,
      osVersion: osVersion,
      appVersion: packageInfo.version,
      appBuildNumber: packageInfo.buildNumber,
      packageName: packageInfo.packageName,
    );
  }

  /// Get locale information
  static String? getLocale() {
    try {
      return WidgetsBinding.instance.platformDispatcher.locale.toString();
    } catch (_) {
      return null;
    }
  }

  /// Get country code from locale (e.g., "en_US" -> "US")
  static String? getCountryCode() {
    final locale = getLocale();
    if (locale == null) return null;

    final parts = locale.split('_');
    if (parts.length > 1) {
      return parts[1].toUpperCase();
    }
    return null;
  }
}

/// Container for device information
class DeviceInfo {
  final String platform;
  final String? deviceModel;
  final String? osVersion;
  final String appVersion;
  final String appBuildNumber;
  final String packageName;

  const DeviceInfo({
    required this.platform,
    this.deviceModel,
    this.osVersion,
    required this.appVersion,
    required this.appBuildNumber,
    required this.packageName,
  });

  @override
  String toString() {
    return 'DeviceInfo(platform: $platform, model: $deviceModel, os: $osVersion, appVersion: $appVersion)';
  }
}
