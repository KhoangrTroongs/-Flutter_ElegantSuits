# Task Allocation for Elegant Suits App (4 Members)

## Project Structure Overview
The project has been restructured to support both Admin and User (Client) roles.

- `lib/screens/admin/`: Contains all existing Admin screens.
- `lib/screens/client/`: New folder for User screens (Home, Cart, Product, Profile).
- `lib/widgets/admin/`: Admin-specific widgets (e.g., CustomDrawer).
- `lib/widgets/client/`: User-specific widgets.
- `lib/widgets/common/`: Shared widgets.

## Roles & Responsibilities

### Member 1: Authentication & Core Logic
- **Focus**: Login, Registration, Routing, State Management (Auth).
- **Tasks**:
    - Update `LoginScreen` (`screens/admin/auth/login_screen.dart`) or create a shared Login screen to handle both Admin and User login.
    - Create `RegisterScreen` for new Users (`screens/client/auth/register_screen.dart`).
    - Implement Logic to navigate to `AdminDashboard` or `ClientHomeScreen` after login based on Role.
    - Ensure `AuthProvider` handles User state correctly.

### Member 2: Client Home & Product Discovery
- **Focus**: UI/UX for Home and Product Listing.
- **Tasks**:
    - Design `HomeScreen` (`screens/client/home/home_screen.dart`): Banners, Categories, Featured Products.
    - Design `ProductListScreen` (`screens/client/product/product_list_screen.dart`): Grid/List view of products with filters.
    - Design `ProductDetailScreen`: Show full details, images, sizes, and "Add to Cart" button.

### Member 3: Cart, Order & Payment
- **Focus**: Shopping flow.
- **Tasks**:
    - Build `CartScreen` (`screens/client/cart/cart_screen.dart`): Show items, adjust quantity, total price.
    - Build `CheckoutScreen`: Address input, Payment method selection (COD/VNPay).
    - Handle Order Submission to Backend.
    - Order Success/Failure screens.

### Member 4: User Profile & Admin Maintenance
- **Focus**: User Account & Support.
- **Tasks**:
    - Build `ProfileScreen` (`screens/client/profile/profile_screen.dart`): User info, Edit Profile.
    - Build `OrderHistoryScreen`: List of past orders for the logged-in user.
    - Assist Member 1 with Admin/User separation logic if needed.
    - Verify Admin screens (`screens/admin/`) still work correctly after restructuring.

## Next Steps
1. **Pull the latest code.**
2. **Check `lib/main.dart`** to ensure it runs without errors.
3. **Start working** in your designated folders in `lib/screens/client/`.
