import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/core/utils/samsung_device_utils.dart';

/// DTA-4-5 회귀 테스트.
///
/// 원래 버그: `shouldUseWorkManager()`에 플랫폼 가드가 없어 iOS에서도 true를
/// 반환했고, 그 결과 Android 전용 WorkManager 경로를 타서 앱 실행 시
/// `PlatformException(channel-error, ...WorkmanagerHostApi.initialize)` 배너가 떴다.
///
/// 이 버그는 실기기 실행으로만 발견됐다. 아래 테스트들은 순수 Dart로 같은 것을 잡는다.
///
/// ⚠️ setUp의 채널 모킹은 **장식이 아니라 하중을 받는 부분이다.** 모킹 없이 테스트를
/// 추가하면 가드가 아니라 MissingPluginException 때문에 통과하는 무의미한 테스트가 된다.
/// 새 테스트를 넣을 때는 반드시 변이 검증(가드를 지우고 죽는지 확인)까지 하십시오.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // permission_handler의 플랫폼 채널.
  const permissionChannel = MethodChannel('flutter.baseflow.com/permissions/methods');
  // isSamsungDevice()가 가드를 지나면 도달하는 채널 둘.
  const deviceInfoChannel = MethodChannel('kr.bluesky.dodo/device_info');
  const systemPropsChannel = MethodChannel('kr.bluesky.dodo/system_properties');

  // ⚠️ 이 모킹이 없으면 이 파일의 테스트는 **버그를 잡지 못한다.**
  //
  // 변이 검증으로 확인한 사실: 가드를 제거해도 모킹 없이는 테스트가 통과한다.
  // 테스트 환경에는 permission_handler 채널이 없어 shouldUseWorkManager() 안의
  // `Permission.ignoreBatteryOptimizations.status`가 MissingPluginException을
  // 던지고, 그 함수의 catch가 삼킨 뒤 마지막 `return false`로 빠지기 때문이다.
  // 즉 "가드가 있어서 false"가 아니라 "예외가 나서 false"였다.
  //
  // 실기기 iOS에서는 채널이 살아 있어 denied(0)를 돌려주고, `!isGranted`가 참이
  // 되어 true를 반환한다 — 그것이 원래 버그다. 아래 모킹이 그 조건을 재현한다.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (call) async {
      switch (call.method) {
        case 'checkPermissionStatus':
          // 0 = PermissionStatus.denied — 실기기 iOS가 Android 전용 권한에 주는 값
          return 0;
        case 'requestPermissions':
          // 키는 Permission.value 다. ignoreBatteryOptimizations 는 Permission._(16).
          // 0을 쓰면 Permission.calendar 를 가리켜 엉뚱한 mock이 된다.
          return <int, int>{16: 0};
        default:
          return null;
      }
    });

    // ⚠️ HIGH-B: 이 두 모킹이 없으면 isSamsungDevice() 테스트가 **무의미해진다.**
    // 가드를 지워도 MissingPluginException → catch → false 로 빠져 테스트가 통과한다.
    // 즉 "가드가 있어서 false"가 아니라 "예외가 나서 false"다 — 이 파일이 처음
    // 저질렀던 것과 똑같은 결함이다. samsung을 돌려주게 해서, false를 만들 수 있는
    // 것이 **플랫폼 가드뿐이도록** 만든다.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(deviceInfoChannel, (call) async {
      if (call.method == 'getManufacturer') return 'samsung';
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(systemPropsChannel, (call) async {
      if (call.method == 'getBrand') return 'samsung';
      return null;
    });
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(permissionChannel, null);
    messenger.setMockMethodCallHandler(deviceInfoChannel, null);
    messenger.setMockMethodCallHandler(systemPropsChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('shouldUseWorkManager() 플랫폼 가드', () {
    test('iOS에서는 false — Android 전용 경로를 타면 안 된다', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await SamsungDeviceUtils.shouldUseWorkManager(), isFalse);
    });

    test('macOS에서도 false', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(await SamsungDeviceUtils.shouldUseWorkManager(), isFalse);
    });
  });

  group('isSamsungDevice() 플랫폼 가드 (기존 동작 유지)', () {
    test('iOS에서는 false', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await SamsungDeviceUtils.isSamsungDevice(), isFalse);
    });
  });

  group('배터리 최적화 술어는 non-Android에서 true', () {
    // "배터리 최적화에서 자유로운가?" — Android 외에는 그 제약 자체가 없으므로 참.
    // DeviceUtils의 형제 구현과 같은 값이어야 한다.
    // (BatteryOptimizationService는 isIgnoringBatteryOptimizations만 대응 함수가 있고
    //  true를 돌려준다. requestBatteryOptimizationExemption의 대응 함수는
    //  requestIgnoreBatteryOptimizations()이고 반환형이 void라 비교 대상이 아니다.)
    // 여기서만 false를 주면 호출자가 iOS 사용자에게 존재하지 않는 Android
    // 설정 안내를 띄우게 된다.
    test('isIgnoringBatteryOptimizations()는 iOS에서 true', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        await SamsungDeviceUtils.isIgnoringBatteryOptimizations(),
        isTrue,
      );
    });

    test('requestBatteryOptimizationExemption()은 iOS에서 true', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        await SamsungDeviceUtils.requestBatteryOptimizationExemption(),
        isTrue,
      );
    });
  });
}
