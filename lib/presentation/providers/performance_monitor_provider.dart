import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// 성능 모니터링 데이터 클래스
class PerformanceMetrics {
  final int todoLoadTime; // 밀리초
  final int filterChangeLatency; // 밀리초
  final int imageLoadTime; // 밀리초
  final int memoryUsageMB;
  final DateTime timestamp;
  final int totalTodosLoaded;
  final int cachedImagesCount;

  const PerformanceMetrics({
    required this.todoLoadTime,
    required this.filterChangeLatency,
    required this.imageLoadTime,
    required this.memoryUsageMB,
    required this.timestamp,
    required this.totalTodosLoaded,
    required this.cachedImagesCount,
  });

  /// 성능 요약
  String getSummary() {
    return '''
성능 모니터링 리포트
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 할일 로드 시간: ${todoLoadTime}ms
🔄 필터 변경 레이턴시: ${filterChangeLatency}ms
🖼️ 이미지 로드 시간: ${imageLoadTime}ms
💾 메모리 사용량: ${memoryUsageMB}MB
📦 로드된 할일: $totalTodosLoaded개
🎯 캐시된 이미지: $cachedImagesCount개
⏰ 측정 시간: ${timestamp.toString().split('.')[0]}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// 성능 평가
  String getPerformanceGrade() {
    final score = _calculateScore();
    if (score >= 90) return '🟢 우수 (A)';
    if (score >= 75) return '🟡 양호 (B)';
    if (score >= 60) return '🔴 보통 (C)';
    return '⚠️ 미흡 (D)';
  }

  /// 성능 점수 계산 (0-100)
  int _calculateScore() {
    int score = 100;

    // 할일 로드 시간 (목표: < 500ms)
    if (todoLoadTime > 1000) score -= 30;
    else if (todoLoadTime > 500) score -= 15;

    // 필터 변경 레이턴시 (목표: < 10ms)
    if (filterChangeLatency > 100) score -= 25;
    else if (filterChangeLatency > 50) score -= 10;

    // 이미지 로드 시간 (목표: < 100ms)
    if (imageLoadTime > 500) score -= 25;
    else if (imageLoadTime > 200) score -= 10;

    // 메모리 사용량 (목표: < 200MB)
    if (memoryUsageMB > 400) score -= 20;
    else if (memoryUsageMB > 250) score -= 10;

    return score.clamp(0, 100);
  }

  /// 성능 권장사항
  List<String> getRecommendations() {
    final recommendations = <String>[];

    if (todoLoadTime > 500) {
      recommendations.add('⚠️ 할일 로드 시간이 깁니다. 데이터베이스 쿼리 최적화를 검토하세요.');
    }

    if (filterChangeLatency > 10) {
      recommendations.add('✅ 필터 변경 레이턴시가 양호합니다. (이미 최적화됨)');
    } else if (filterChangeLatency > 50) {
      recommendations.add('⚠️ 필터 변경이 느립니다. Provider 최적화를 검토하세요.');
    }

    if (imageLoadTime > 200) {
      recommendations.add('⚠️ 이미지 로드가 느립니다. 이미지 캐싱 상태를 확인하세요.');
    } else {
      recommendations.add('✅ 이미지 로드 성능이 우수합니다.');
    }

    if (memoryUsageMB > 250) {
      recommendations.add('⚠️ 메모리 사용량이 높습니다. 캐시 정리를 실행하세요.');
    } else {
      recommendations.add('✅ 메모리 사용량이 양호합니다.');
    }

    return recommendations;
  }
}

/// 성능 모니터링 Notifier (Riverpod 3.0 호환)
class PerformanceMonitorNotifier extends Notifier<PerformanceMetrics?> {
  /// 성능 측정 시작
  final Map<String, Stopwatch> _stopwatches = {};

  @override
  PerformanceMetrics? build() => null;

  void startMeasurement(String label) {
    _stopwatches[label] = Stopwatch()..start();
    logger.d('⏱️ 성능 측정 시작: $label');
  }

  void endMeasurement(String label) {
    final stopwatch = _stopwatches[label];
    if (stopwatch != null) {
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      logger.d('⏱️ 성능 측정 완료: $label → ${elapsed}ms');
      _stopwatches.remove(label);
    }
  }

  int getMeasurement(String label) {
    final stopwatch = _stopwatches[label];
    return stopwatch?.elapsedMilliseconds ?? 0;
  }

  /// 성능 메트릭 업데이트
  void updateMetrics({
    required int todoLoadTime,
    required int filterChangeLatency,
    required int imageLoadTime,
    required int memoryUsageMB,
    required int totalTodosLoaded,
    required int cachedImagesCount,
  }) {
    state = PerformanceMetrics(
      todoLoadTime: todoLoadTime,
      filterChangeLatency: filterChangeLatency,
      imageLoadTime: imageLoadTime,
      memoryUsageMB: memoryUsageMB,
      timestamp: DateTime.now(),
      totalTodosLoaded: totalTodosLoaded,
      cachedImagesCount: cachedImagesCount,
    );

    logger.d(state!.getSummary());
    logger.d('등급: ${state!.getPerformanceGrade()}');

    for (final rec in state!.getRecommendations()) {
      logger.d(rec);
    }
  }

  /// 성능 메트릭 초기화
  void reset() {
    state = null;
    _stopwatches.clear();
    logger.d('🔄 성능 메트릭 초기화됨');
  }
}

/// 성능 모니터링 Provider
final performanceMonitorProvider =
    NotifierProvider<PerformanceMonitorNotifier, PerformanceMetrics?>(
  PerformanceMonitorNotifier.new,
);
