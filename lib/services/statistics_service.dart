import 'dart:convert';
import '../models/statistics.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class StatisticsService {
  /// Lấy thống kê tổng quan
  Future<StatisticsOverview> getOverviewStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String endpoint = '${ApiConfig.baseUrl}/Statistics/overview';

    List<String> params = [];
    if (startDate != null) {
      params.add('startDate=${startDate.toIso8601String().split('T')[0]}');
    }
    if (endDate != null) {
      params.add('endDate=${endDate.toIso8601String().split('T')[0]}');
    }

    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }

    final response = await ApiService.get(endpoint);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return StatisticsOverview.fromJson(data);
    } else {
      throw Exception('Lỗi tải thống kê: ${response.statusCode}');
    }
  }

  /// Lấy thống kê hôm nay
  Future<StatisticsOverview> getTodayStatistics() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return getOverviewStatistics(startDate: startOfDay, endDate: today);
  }

  /// Lấy thống kê tháng này
  Future<StatisticsOverview> getMonthStatistics() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return getOverviewStatistics(startDate: startOfMonth, endDate: now);
  }

  /// Lấy thống kê tổng (không giới hạn thời gian)
  Future<StatisticsOverview> getAllTimeStatistics() async {
    // Không truyền startDate và endDate để lấy tất cả
    return getOverviewStatistics();
  }
}
