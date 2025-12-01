/// Performance monitoring providers for app diagnostics.
///
/// Tracks key performance metrics including load times, memory usage,
/// and provides performance grades with actionable recommendations.
///
/// Key providers:
/// - [performanceMonitorProvider]: Main performance notifier
///
/// Metrics tracked:
/// - Todo list load time (target: <500ms)
/// - Filter change latency (target: <10ms)
/// - Image load time (target: <100ms)
/// - Memory usage (target: <200MB)
///
/// See also:
/// - [PerformanceMetrics] for metric data structure
/// - [paginationProvider] for list performance optimization
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// Data class containing performance measurements.
///
/// Provides summary reports, performance grades (A-D), and
/// actionable recommendations based on measured values.
class PerformanceMetrics {
  /// Time to load todo list in milliseconds.
  final int todoLoadTime;

  /// Time to apply filter changes in milliseconds.
  final int filterChangeLatency;

  /// Time to load images in milliseconds.
  final int imageLoadTime;

  /// Current memory usage in megabytes.
  final int memoryUsageMB;

  /// When metrics were captured.
  final DateTime timestamp;

  /// Number of todos loaded.
  final int totalTodosLoaded;

  /// Number of images in cache.
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

  /// Generates a formatted performance summary report.
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

  /// Returns a letter grade (A-D) based on overall performance score.
  String getPerformanceGrade() {
    final score = _calculateScore();
    if (score >= 90) return '🟢 Excellent (A)';
    if (score >= 75) return '🟡 Good (B)';
    if (score >= 60) return '🔴 Fair (C)';
    return '⚠️ Poor (D)';
  }

  /// Calculates performance score from 0-100 based on metrics.
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

  /// Returns actionable recommendations based on current metrics.
  List<String> getRecommendations() {
    final recommendations = <String>[];

    if (todoLoadTime > 500) {
      recommendations.add('⚠️ Todo load time is slow. Consider optimizing database queries.');
    }

    if (filterChangeLatency > 10) {
      recommendations.add('✅ Filter change latency is good. (Already optimized)');
    } else if (filterChangeLatency > 50) {
      recommendations.add('⚠️ Filter changes are slow. Consider Provider optimization.');
    }

    if (imageLoadTime > 200) {
      recommendations.add('⚠️ Image loading is slow. Check image caching status.');
    } else {
      recommendations.add('✅ Image load performance is excellent.');
    }

    if (memoryUsageMB > 250) {
      recommendations.add('⚠️ Memory usage is high. Run cache cleanup.');
    } else {
      recommendations.add('✅ Memory usage is good.');
    }

    return recommendations;
  }
}

/// Notifier for tracking and reporting performance metrics.
///
/// Supports labeled stopwatch measurements for profiling different
/// operations and aggregates results into [PerformanceMetrics].
///
/// Usage:
/// ```dart
/// final notifier = ref.read(performanceMonitorProvider.notifier);
/// notifier.startMeasurement('todoLoad');
/// // ... operation ...
/// notifier.endMeasurement('todoLoad');
/// ```
class PerformanceMonitorNotifier extends Notifier<PerformanceMetrics?> {
  /// Active stopwatches for ongoing measurements.
  final Map<String, Stopwatch> _stopwatches = {};

  @override
  PerformanceMetrics? build() => null;

  /// Starts a labeled stopwatch measurement.
  void startMeasurement(String label) {
    _stopwatches[label] = Stopwatch()..start();
    logger.d('⏱️ Performance measurement started: $label');
  }

  /// Stops a labeled stopwatch and logs the elapsed time.
  void endMeasurement(String label) {
    final stopwatch = _stopwatches[label];
    if (stopwatch != null) {
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      logger.d('⏱️ Performance measurement complete: $label → ${elapsed}ms');
      _stopwatches.remove(label);
    }
  }

  /// Returns elapsed milliseconds for an active measurement.
  int getMeasurement(String label) {
    final stopwatch = _stopwatches[label];
    return stopwatch?.elapsedMilliseconds ?? 0;
  }

  /// Updates the performance metrics state with new measurements.
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

  /// Resets all metrics and clears active measurements.
  void reset() {
    state = null;
    _stopwatches.clear();
    logger.d('🔄 Performance metrics reset');
  }
}

/// Main provider for performance monitoring.
///
/// Access the notifier to start/stop measurements and update metrics.
final performanceMonitorProvider =
    NotifierProvider<PerformanceMonitorNotifier, PerformanceMetrics?>(
  PerformanceMonitorNotifier.new,
);
