# ⚡ Quick Start - Elegant Suits Admin App

## ✅ Setup Completed!

Dependencies đã được cài đặt thành công!

---

## 🚀 App đang chạy...

Flutter đang build app trên Windows. Vui lòng đợi 2-3 phút.

---

## 📱 Sau khi app mở:

### 1. Login Screen
- Nhập email admin của bạn
- Nhập password
- Click "Login"

### 2. Dashboard
- Xem tổng quan
- Click vào các card để vào từng module:
  - **Products** - Quản lý sản phẩm
  - **Orders** - Quản lý đơn hàng
  - **Users** - Quản lý người dùng
  - **Coupons** - Quản lý mã giảm giá

---

## 🔧 Cấu hình API

**QUAN TRỌNG**: Trước khi login, bạn cần:

1. **Chạy API .NET**:
```bash
cd e:\DACN\DACN_ElegantSuits\2280600725-NgoHuuDuc
dotnet run
```

2. **Update API URL** trong app:

Mở file: `lib/config/api_config.dart`

Thay đổi:
```dart
static const String baseUrl = 'https://localhost:7001/api';
```

Thành URL API của bạn (nếu khác).

---

## 🎯 Test Login

Sử dụng tài khoản admin từ database:

**Option 1**: Tài khoản có sẵn
- Email: admin@example.com
- Password: Admin@123

**Option 2**: Tạo tài khoản mới
- Vào SQL Server
- Chạy script tạo admin user
- Sử dụng email/password đó để login

---

## 📋 Các Chức Năng

### Products Management
- ➕ Add Product: Click icon "+" trên AppBar
- ✏️ Edit Product: Click icon "edit" trên mỗi product
- 🗑️ Delete Product: Click icon "delete"
- 👁️ Hide/Show: Toggle switch trong form

### Orders Management
- 📋 View Orders: Xem danh sách đơn hàng
- 📝 Order Details: Click vào order để xem chi tiết
- 🔄 Update Status: Dropdown trong order detail

### Users Management
- 👥 View Users: Xem danh sách users
- 🗑️ Delete User: Click icon "delete"
- 👑 Admin Badge: Users có role Admin sẽ có badge đỏ

### Coupons Management
- ➕ Add Coupon: Click icon "+" trên AppBar
- ✏️ Edit Coupon: Click icon "edit"
- 🗑️ Delete Coupon: Click icon "delete"
- ✅ Active/Inactive: Badge màu xanh/đỏ

---

## 🐛 Troubleshooting

### App không kết nối được API?

1. **Kiểm tra API đang chạy**:
```bash
curl https://localhost:7001/api/Test
```

2. **Kiểm tra URL trong code**:
- Mở `lib/config/api_config.dart`
- Đảm bảo `baseUrl` đúng

3. **Nếu dùng Android Emulator**:
- Thay `localhost` bằng `10.0.2.2`

4. **Nếu dùng Windows**:
- Có thể cần disable SSL verification (chỉ cho development)

### Login failed?

1. **Kiểm tra tài khoản trong database**
2. **Kiểm tra API response** trong console
3. **Xem error message** trên app

### Build failed?

```bash
flutter clean
flutter pub get
flutter run -d windows
```

---

## 🎨 Customization

### Thay đổi màu sắc:
`lib/config/app_theme.dart`

### Thay đổi API endpoints:
`lib/config/api_config.dart`

### Thêm chức năng mới:
1. Tạo model trong `lib/models/`
2. Tạo service trong `lib/services/`
3. Tạo provider trong `lib/providers/`
4. Tạo screen trong `lib/screens/`

---

## 📞 Support

Nếu gặp vấn đề:
1. Kiểm tra console output
2. Xem file `SETUP_INSTRUCTIONS.md`
3. Kiểm tra API logs

---

## ✅ Checklist

- [x] Flutter pub get ✅
- [x] App đang build ⏳
- [ ] API đang chạy
- [ ] Login thành công
- [ ] Test các chức năng

---

**App sẽ mở trong vài phút. Hãy kiên nhẫn! 🚀**

