import 'dart:convert';
import '../config/api_config.dart';
import '../models/coupon.dart';
import 'api_service.dart';

class CouponService {
  // CouponApi trả về trực tiếp array, không wrap trong ResponseDTO

  Future<List<Coupon>> getCoupons() async {
    try {
      final response = await ApiService.get(ApiConfig.coupons);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        // Backend trả về trực tiếp mảng, không wrap trong ResponseDTO
        if (data is List) {
          return data.map((json) => Coupon.fromJson(json)).toList();
        }
        // Nếu là Map thì có thể là wrap trong ResponseDTO
        if (data is Map<String, dynamic>) {
          final listData = data['Data'] ?? data['data'] ?? data;
          if (listData is List) {
            return listData.map((json) => Coupon.fromJson(json)).toList();
          }
        }
        return [];
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching coupons: $e');
    }
  }

  Future<Coupon> createCoupon(Coupon coupon) async {
    try {
      final response = await ApiService.post(
        ApiConfig.coupons,
        coupon.toJson(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return Coupon.fromJson(data);
      }
      throw Exception('Failed to create coupon: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating coupon: $e');
    }
  }

  Future<Coupon> updateCoupon(int id, Coupon coupon) async {
    try {
      final response = await ApiService.put(
        ApiConfig.couponById(id),
        coupon.toJson(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return Coupon.fromJson(data);
      }
      throw Exception('Failed to update coupon: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating coupon: $e');
    }
  }

  Future<void> deleteCoupon(int id) async {
    try {
      final response = await ApiService.delete(ApiConfig.couponById(id));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to delete coupon: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting coupon: $e');
    }
  }
}
