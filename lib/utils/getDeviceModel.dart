import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceModel() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return '${androidInfo.brand} ${androidInfo.model}';
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    return '${iosInfo.name} ${iosInfo.utsname.machine}';
  }
  return 'Unknown Device';
}