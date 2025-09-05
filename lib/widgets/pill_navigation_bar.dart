import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants/app_constants.dart';

class PillNavigationBar extends StatelessWidget {
  const PillNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Container(
          height: AppConstants.navigationBarHeight,
          margin: AppConstants.navigationBarPadding,
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(AppConstants.navigationBarRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavigationItem(
                icon: Icons.photo_library_outlined,
                activeIcon: Icons.photo_library,
                label: 'Albums',
                index: AppConstants.albumsPageIndex,
                isActive: appProvider.currentPageIndex == AppConstants.albumsPageIndex,
                onTap: () => appProvider.setCurrentPageIndex(AppConstants.albumsPageIndex),
              ),
              _NavigationItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Accueil',
                index: AppConstants.homePageIndex,
                isActive: appProvider.currentPageIndex == AppConstants.homePageIndex,
                onTap: () => appProvider.setCurrentPageIndex(AppConstants.homePageIndex),
              ),
              _NavigationItem(
                icon: Icons.swipe_outlined,
                activeIcon: Icons.swipe,
                label: 'Swipe',
                index: AppConstants.swipePageIndex,
                isActive: appProvider.currentPageIndex == AppConstants.swipePageIndex,
                onTap: () => appProvider.setCurrentPageIndex(AppConstants.swipePageIndex),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final bool isActive;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.swipeAnimationDuration,
        curve: AppConstants.defaultAnimationCurve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppConstants.primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppConstants.primaryColor : Colors.white70,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive ? AppConstants.primaryColor : Colors.white70,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}