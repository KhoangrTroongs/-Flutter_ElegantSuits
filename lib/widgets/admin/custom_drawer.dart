import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import '../../screens/admin/dashboard/dashboard_screen.dart';
import '../../screens/admin/products/products_list_screen.dart';
import '../../screens/admin/orders/orders_list_screen.dart';
import '../../screens/admin/users/users_list_screen.dart';
import '../../screens/admin/coupons/coupons_list_screen.dart';
import '../../screens/admin/inventory/inventory_screen.dart';
import '../../screens/admin/pos/pos_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Drawer(
      backgroundColor: AppTheme.surfaceColor,
      child: Column(
        children: [
          // Header
          _buildHeader(user?.displayName ?? 'Admin', user?.email ?? ''),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerMenuItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () => _navigateTo(
                    context,
                    const DashboardScreen(),
                    replace: true,
                  ),
                ),
                _DrawerMenuItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  title: 'Products',
                  onTap: () => _navigateTo(context, const ProductsListScreen()),
                ),
                _DrawerMenuItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  title: 'Orders',
                  onTap: () => _navigateTo(context, const OrdersListScreen()),
                ),
                _DrawerMenuItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  title: 'Customers',
                  onTap: () => _navigateTo(context, const UsersListScreen()),
                ),
                _DrawerMenuItem(
                  icon: Icons.local_offer_outlined,
                  activeIcon: Icons.local_offer,
                  title: 'Coupons',
                  onTap: () => _navigateTo(context, const CouponsListScreen()),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Divider(color: AppTheme.borderColor),
                ),
                _DrawerMenuItem(
                  icon: Icons.warehouse_outlined,
                  activeIcon: Icons.warehouse,
                  title: 'Quản lý kho',
                  onTap: () => _navigateTo(context, const InventoryScreen()),
                ),
                _DrawerMenuItem(
                  icon: Icons.point_of_sale_outlined,
                  activeIcon: Icons.point_of_sale,
                  title: 'Tạo đơn hàng (POS)',
                  onTap: () => _navigateTo(context, const PosScreen()),
                ),
              ],
            ),
          ),
          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.goldColor, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.diamond,
                  size: 24,
                  color: AppTheme.goldColor,
                ),
              ),
              const SizedBox(width: 12),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.goldGradient.createShader(bounds),
                child: const Text(
                  'ELEGANT SUITS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // User Info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.goldColor, width: 2),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.person,
                    size: 28,
                    color: AppTheme.goldColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        color: AppTheme.textMuted.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5)),
        ),
      ),
      child: InkWell(
        onTap: () async {
          await Provider.of<AuthProvider>(context, listen: false).logout();
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.errorColor.withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: AppTheme.errorColor, size: 20),
              SizedBox(width: 10),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(
    BuildContext context,
    Widget screen, {
    bool replace = false,
  }) {
    Navigator.pop(context);
    if (replace) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    } else {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    }
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.textSecondary, size: 22),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
