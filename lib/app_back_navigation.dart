import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppBackNavigation {
  static const _channel = MethodChannel('com.ecoimpact.itiwi/navigation');

  static Future<void> backgroundApp() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod<void>('backgroundApp');
        return;
      } on PlatformException {
        // Let Android close the activity if this build lacks the native handler.
      } on MissingPluginException {
        // Let Android close the activity if this build lacks the native handler.
      }
    }
    await SystemNavigator.pop();
  }
}
