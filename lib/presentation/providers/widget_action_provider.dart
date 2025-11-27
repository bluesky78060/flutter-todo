import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// 위젯 액션 처리 (나중에 구현)
/// 현재는 placeholder - 향후 MethodChannel과 연동할 예정
final widgetActionProvider = Provider<void>((ref) {
  logger.d('위젯 액션 프로바이더 초기화');
});
