# 🚀 Setup Instructions - Elegant Suits Admin App

## ✅ Hoàn Thành 100%

Tất cả code đã được tạo xong! Bây giờ bạn chỉ cần chạy app.

---

## 📋 Bước 1: Install Dependencies

```bash
cd e:\DACN\app_elegant_suits
flutter pub get
```

---

## 🔧 Bước 2: Cấu Hình API URL

Mở file `lib/config/api_config.dart` và update base URL:

```dart
static const String baseUrl = 'https://localhost:7001/api';
```

Hoặc nếu API của bạn chạy ở địa chỉ khác, thay đổi URL tương ứng.

---

## 🏃 Bước 3: Chạy App

```bash
flutter run
```

Hoặc trong VS Code/Android Studio: Press F5

---

## 📱 Bước 4: Login

Sử dụng tài khoản admin từ database của bạn:

- Email: admin@example.com
- Password: (password trong database)

---

## 🎯 Các Chức Năng Đã Có

### ✅ Authentication
- Login screen
- JWT token authentication
- Auto-login if token exists
- Logout

### ✅ Dashboard
- Overview cards
- Quick navigation
- Drawer menu

### ✅ Products Management
- List all products
- Add new product
- Edit product
- Delete product
- Show/Hide product
- Category selection

### ✅ Orders Management
- List all orders
- View order details
- Update order status
- Filter by status

### ✅ Users Management
- List all users
- View user details
- Delete user
- Show user roles

### ✅ Coupons Management
- List all coupons
- Create new coupon
- Edit coupon
- Delete coupon
- Enable/Disable coupon
- Set expiry date
- Usage limits

---

## 🔍 Troubleshooting

### Lỗi: "Failed to connect to API"

1. Kiểm tra API đang chạy:
```bash
cd e:\DACN\DACN_ElegantSuits\2280600725-NgoHuuDuc
dotnet run
```

2. Kiểm tra URL trong `lib/config/api_config.dart`

3. Nếu dùng Android Emulator, thay `localhost` bằng `10.0.2.2`

### Lỗi: "Package not found"

```bash
flutter clean
flutter pub get
```

### Lỗi: "Build failed"

```bash
flutter doctor
flutter upgrade
```

---

## 📦 Build APK

```bash
flutter build apk --release
```

APK sẽ được tạo tại: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🎨 Customization

### Thay Đổi Theme

Edit `lib/config/app_theme.dart`:

```dart
static const Color primaryColor = Color(0xFF2C3E50);
static const Color secondaryColor = Color(0xFFE74C3C);
```

### Thay Đổi App Name

Edit `pubspec.yaml`:

```yaml
name: app_elegant_suits
description: "Admin app for Elegant Suits"
```

---

## 📝 Files Created

**Total: 30+ files**

### Config (2 files)
- api_config.dart
- app_theme.dart

### Models (5 files)
- response.dart
- product.dart
- order.dart
- user.dart
- coupon.dart

### Services (6 files)
- api_service.dart
- auth_service.dart
- product_service.dart
- order_service.dart
- user_service.dart
- coupon_service.dart

### Providers (5 files)
- auth_provider.dart
- product_provider.dart
- order_provider.dart
- user_provider.dart
- coupon_provider.dart

### Screens (9 files)
- login_screen.dart
- dashboard_screen.dart
- products_list_screen.dart
- product_form_screen.dart
- orders_list_screen.dart
- order_detail_screen.dart
- users_list_screen.dart
- coupons_list_screen.dart
- coupon_form_screen.dart

### Widgets (1 file)
- custom_drawer.dart

### Main (1 file)
- main.dart

---

## 🎉 Xong!

App đã sẵn sàng để chạy. Chỉ cần:

1. `flutter pub get`
2. Update API URL
3. `flutter run`

**Chúc bạn thành công! 🚀**

