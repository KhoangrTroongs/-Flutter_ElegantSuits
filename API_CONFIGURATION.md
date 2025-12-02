# 🔧 API Configuration Guide

## 📍 Current API URL

File: `lib/config/api_config.dart`

```dart
static const String baseUrl = 'https://localhost:7001/api';
```

---

## 🚀 Bước 1: Chạy API .NET

Trước khi chạy Flutter app, bạn PHẢI chạy API .NET:

```bash
cd e:\DACN\DACN_ElegantSuits\2280600725-NgoHuuDuc
dotnet run
```

API sẽ chạy tại: `https://localhost:7001`

---

## 🔄 Bước 2: Test API

Mở browser và test:

```
https://localhost:7001/api/Test
```

Hoặc dùng curl:

```bash
curl -k https://localhost:7001/api/Test
```

Nếu thấy response → API đang chạy ✅

---

## 📱 Bước 3: Cấu hình cho từng Platform

### Windows Desktop (Đang dùng)
```dart
static const String baseUrl = 'https://localhost:7001/api';
```

### Android Emulator
```dart
static const String baseUrl = 'https://10.0.2.2:7001/api';
```

### iOS Simulator
```dart
static const String baseUrl = 'https://localhost:7001/api';
```

### Physical Device (Same Network)
```dart
static const String baseUrl = 'https://192.168.1.XXX:7001/api';
```
(Thay XXX bằng IP máy chạy API)

---

## 🔐 SSL Certificate Issues

Nếu gặp lỗi SSL certificate, có 2 cách:

### Cách 1: Trust Certificate (Recommended)
```bash
dotnet dev-certs https --trust
```

### Cách 2: Disable SSL Verification (Development Only)

Thêm vào `lib/services/api_service.dart`:

```dart
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// Trong main.dart, thêm:
void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}
```

---

## 🧪 Test Endpoints

### 1. Test Connection
```
GET https://localhost:7001/api/Test
```

### 2. Login
```
POST https://localhost:7001/api/Auth/login
Body: {
  "email": "admin@example.com",
  "password": "Admin@123"
}
```

### 3. Get Products
```
GET https://localhost:7001/api/Products
Headers: {
  "Authorization": "Bearer YOUR_TOKEN"
}
```

---

## 🐛 Troubleshooting

### Lỗi: "Connection refused"
- ✅ Kiểm tra API đang chạy
- ✅ Kiểm tra port 7001 không bị block
- ✅ Kiểm tra firewall

### Lỗi: "SSL handshake failed"
- ✅ Trust certificate: `dotnet dev-certs https --trust`
- ✅ Hoặc disable SSL verification (dev only)

### Lỗi: "Timeout"
- ✅ Tăng timeout trong `api_config.dart`:
```dart
static const Duration timeout = Duration(seconds: 60);
```

### Lỗi: "401 Unauthorized"
- ✅ Kiểm tra token
- ✅ Login lại
- ✅ Kiểm tra token expiry

---

## 📝 API Endpoints List

```dart
// Auth
POST   /api/Auth/login
POST   /api/Auth/register

// Products
GET    /api/Products
GET    /api/Products/{id}
POST   /api/Products
PUT    /api/Products/{id}
DELETE /api/Products/{id}

// Orders
GET    /api/Orders
GET    /api/Orders/{id}
PUT    /api/Orders/{id}/status

// Users
GET    /api/Users
GET    /api/Users/{id}
DELETE /api/Users/{id}

// Coupons
GET    /api/Coupon
POST   /api/Coupon
PUT    /api/Coupon/{id}
DELETE /api/Coupon/{id}

// Categories
GET    /api/Categories

// Statistics
GET    /api/StatisticsApi/dashboard
```

---

## ✅ Checklist

- [ ] API .NET đang chạy
- [ ] Test endpoint `/api/Test` thành công
- [ ] API URL trong app đúng
- [ ] SSL certificate trusted (nếu cần)
- [ ] Có tài khoản admin để login

---

**Sau khi hoàn thành checklist, app sẽ kết nối API thành công! 🎉**

