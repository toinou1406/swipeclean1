import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants/app_constants.dart';
import '../widgets/pill_navigation_bar.dart';
import 'home_screen.dart';
import 'albums_screen.dart';
import 'swipe_screen.dart';
import 'permissions_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.isLoading) {
          return Scaffold(
            backgroundColor: AppConstants.backgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Initialisation...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Check permissions first
        if (!appProvider.hasAllPermissions) {
          return PermissionsScreen(
            onPermissionsGranted: () {
              // Refresh the provider to reload with permissions
              appProvider.refreshAlbums();
            },
          );
        }

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: Stack(
            children: [
              // Page Content
              PageView(
                controller: PageController(initialPage: appProvider.currentPageIndex),
                onPageChanged: (index) => appProvider.setCurrentPageIndex(index),
                children: const [
                  AlbumsScreen(),
                  HomeScreen(),
                  SwipeScreen(),
                ],
              ),
              
              // Navigation Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: const PillNavigationBar(),
              ),
            ],
          ),
        );
      },
    );
  }
}