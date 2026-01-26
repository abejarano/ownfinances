import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import "package:ownfinances/features/auth/application/controllers/session_controller.dart";
import 'package:ownfinances/l10n/app_localizations.dart';
import 'package:ownfinances/features/settings/application/controllers/settings_controller.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Helper for active state
    bool isActive(String route) {
      if (route == '/') return currentRoute == '/';
      return currentRoute.startsWith(route);
    }

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context),

          _buildSectionTitle(context, l10n.drawerManagement),
          _buildNavItem(
            context,
            icon: Icons.category_outlined,
            label: l10n.drawerCategories,
            route: '/categories',
            selected: isActive('/categories'),
            onTap: () => context.push('/categories'),
          ),
          _buildNavItem(
            context,
            icon: Icons.account_balance_wallet_outlined,
            label: l10n.drawerAccounts,
            route: '/accounts',
            selected: isActive('/accounts'),
            onTap: () => context.push('/accounts'),
          ),
          _buildNavItem(
            context,
            icon: Icons.credit_card_outlined,
            label: l10n.drawerDebts,
            route: '/debts',
            selected: isActive('/debts'),
            onTap: () => context.push('/debts'),
          ),
          _buildNavItem(
            context,
            icon: Icons.flag_outlined,
            label: l10n.drawerGoals,
            route: '/goals',
            selected: isActive('/goals'),
            onTap: () => context.push('/goals'),
          ),
          _buildNavItem(
            context,
            icon: Icons.repeat_outlined,
            label: l10n.drawerRecurring,
            route: '/recurring',
            selected: isActive('/recurring'),
            onTap: () => context.push('/recurring'),
          ),
          const Divider(),
          _buildSectionTitle(context, l10n.drawerSettings),
          _buildNavItem(
            context,
            icon: Icons.settings_outlined,
            label: l10n.settingsTitle,
            route: '/settings',
            selected: isActive('/settings'),
            onTap: () => context.go('/settings'),
          ),
          const Divider(),
          _buildSectionTitle(context, l10n.drawerAccount),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: Text(
              l10n.drawerLogout,
              style: const TextStyle(color: AppColors.danger),
            ),
            onTap: () async {
              await context.read<SessionController>().logout();
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.settingsVersionValue('1.0.0'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DrawerHeader(
      decoration: const BoxDecoration(color: AppColors.surface1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'images/logo-horizontal.png',
            height: 50,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appTagline,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Text(
              l10n.drawerMainCurrency(
                context.watch<SettingsController>().primaryCurrency,
              ),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.primary.withOpacity(0.05),
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      onTap: () {
        // Close drawer first
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
