import 'package:flutter/material.dart';
import '../models/coupon.dart';
import '../services/coupon_service.dart';

class CouponProvider extends ChangeNotifier {
  final CouponService _couponService = CouponService();

  List<Coupon> _coupons = [];
  bool _isLoading = false;
  String? _error;

  List<Coupon> get coupons => _coupons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Lấy danh sách mã giảm giá
  Future<void> fetchCoupons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _coupons = await _couponService.getCoupons();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Thêm mã giảm giá mới
  Future<bool> addCoupon(Coupon coupon) async {
    try {
      final newCoupon = await _couponService.createCoupon(coupon);
      _coupons.add(newCoupon);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Cập nhật mã giảm giá
  Future<bool> updateCoupon(int id, Coupon coupon) async {
    try {
      final updatedCoupon = await _couponService.updateCoupon(id, coupon);
      final index = _coupons.indexWhere((c) => c.id == id);
      if (index != -1) {
        _coupons[index] = updatedCoupon;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Xóa mã giảm giá
  Future<bool> deleteCoupon(int id) async {
    try {
      await _couponService.deleteCoupon(id);
      _coupons.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
