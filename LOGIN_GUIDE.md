# 🔐 Login Guide - Elegant Suits Admin App

## 📱 App đang build...

Flutter đang build app cho Chrome. Vui lòng đợi 1-2 phút.

---

## 🎯 Sau khi app mở

### Bước 1: Màn hình Splash
- App sẽ hiển thị logo "Elegant Suits Admin"
- Loading spinner
- Tự động chuyển sang Login screen

### Bước 2: Login Screen
- Nhập **Email**
- Nhập **Password**
- Click **Login**

---

## 👤 Tài Khoản Test

### Option 1: Tài khoản mặc định (nếu có trong DB)
```
Email: admin@example.com
Password: Admin@123
```

### Option 2: Tạo tài khoản admin mới

Chạy SQL trong database:

```sql
-- Tạo user admin
INSERT INTO AspNetUsers (Id, UserName, NormalizedUserName, Email, NormalizedEmail, EmailConfirmed, PasswordHash, SecurityStamp, ConcurrencyStamp, PhoneNumber, PhoneNumberConfirmed, TwoFactorEnabled, LockoutEnd, LockoutEnabled, AccessFailedCount)
VALUES (
  NEWID(),
  'admin@elegantsuit.com',
  'ADMIN@ELEGANTSUIT.COM',
  'admin@elegantsuit.com',
  'ADMIN@ELEGANTSUIT.COM',
  1,
  'AQAAAAEAACcQAAAAEJ...', -- Hash của password
  NEWID(),
  NEWID(),
  NULL,
  0,
  0,
  NULL,
  1,
  0
);

-- Gán role Administrator
INSERT INTO AspNetUserRoles (UserId, RoleId)
SELECT u.Id, r.Id
FROM AspNetUsers u, AspNetRoles r
WHERE u.Email = 'admin@elegantsuit.com'
AND r.Name = 'Administrator';
```

### Option 3: Dùng tài khoản có sẵn trong DB

Kiểm tra users trong database:

```sql
SELECT u.Email, r.Name as Role
FROM AspNetUsers u
LEFT JOIN AspNetUserRoles ur ON u.Id = ur.UserId
LEFT JOIN AspNetRoles r ON ur.RoleId = r.Id
WHERE r.Name = 'Administrator';
```

---

## ⚠️ QUAN TRỌNG: Chạy API trước

Trước khi login, đảm bảo API đang chạy:

```bash
cd e:\DACN\DACN_ElegantSuits\2280600725-NgoHuuDuc
dotnet run
```

Kiểm tra API:
```
https://localhost:7001/api/Test
```

---

## 🔄 Quy trình Login

```
1. User nhập email/password
   ↓
2. App gọi POST /api/Auth/login
   ↓
3. API validate credentials
   ↓
4. API trả về JWT token + user info
   ↓
5. App lưu token vào SharedPreferences
   ↓
6. App chuyển sang Dashboard
```

---

## 🐛 Troubleshooting

### Lỗi: "Login failed"

**Nguyên nhân:**
- Email/password sai
- API không chạy
- API URL sai

**Giải pháp:**
1. Kiểm tra API đang chạy
2. Kiểm tra email/password trong database
3. Xem console log để biết lỗi cụ thể

### Lỗi: "Connection refused"

**Nguyên nhân:**
- API không chạy
- URL sai

**Giải pháp:**
1. Chạy API: `dotnet run`
2. Kiểm tra URL trong `lib/config/api_config.dart`

### Lỗi: "SSL handshake failed"

**Nguyên nhân:**
- Certificate không trusted

**Giải pháp:**
```bash
dotnet dev-certs https --trust
```

### Lỗi: "401 Unauthorized"

**Nguyên nhân:**
- Credentials sai
- User không có role Administrator

**Giải pháp:**
1. Kiểm tra password trong database
2. Kiểm tra user có role Administrator

---

## 📝 API Request Example

### Login Request
```http
POST https://localhost:7001/api/Auth/login
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "Admin@123"
}
```

### Login Response (Success)
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "xxx-xxx-xxx",
      "email": "admin@example.com",
      "userName": "Admin",
      "roles": ["Administrator"]
    }
  }
}
```

### Login Response (Failed)
```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

---

## ✅ Sau khi Login thành công

App sẽ chuyển sang **Dashboard** với:

- 📦 **Products** - Quản lý sản phẩm
- 🛒 **Orders** - Quản lý đơn hàng
- 👥 **Users** - Quản lý người dùng
- 🎟️ **Coupons** - Quản lý mã giảm giá

---

## 🔓 Logout

Click icon **Logout** trên AppBar hoặc trong Drawer menu.

Token sẽ bị xóa và app quay về Login screen.

---

## 📱 Auto-Login

Nếu đã login trước đó và token còn hạn:
- App sẽ tự động login
- Chuyển thẳng sang Dashboard
- Không cần nhập lại email/password

---

**App sẽ mở trong Chrome sau khi build xong! 🚀**

