# 📱 Elegant Suits Admin App

Flutter admin app for managing Elegant Suits e-commerce store.

## ✅ Features

- 🔐 **Authentication** - Login with email/password
- 📊 **Dashboard** - Overview statistics
- 🛍️ **Products Management** - CRUD operations for products
- 📦 **Orders Management** - View and update order status
- 👥 **Users Management** - View and manage users
- 🎟️ **Coupons Management** - Create and manage discount coupons

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.10.1 or higher)
- Dart SDK
- Android Studio / VS Code
- .NET API running (from DACN_ElegantSuits project)

### Installation

1. **Install dependencies**
```bash
flutter pub get
```

2. **Update API URL**

Edit `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'https://your-api-url.com/api';
```

3. **Run the app**
```bash
flutter run
```

## 📱 Screens

- Login Screen
- Dashboard
- Products List & Form
- Orders List & Detail
- Users List
- Coupons List & Form

## 🔐 Authentication

JWT token authentication with SharedPreferences storage.

## 📦 Dependencies

- provider (State management)
- http & dio (API calls)
- shared_preferences (Storage)
- intl (Date formatting)
- fl_chart (Charts)

## 🛠️ Build

```bash
flutter build apk --release
```

## 👨‍💻 Author

Ngo Huu Duc - 2280600725
"# DACN_APP_ElegantSuits" 
