import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../constants/app_constants.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionsScreen({
    super.key,
    required this.onPermissionsGranted,
  });

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final PermissionService _permissionService = PermissionService.instance;
  bool _isLoading = false;
  Map<String, bool> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    await _permissionService.refreshPermissionStatus();
    _permissionStatus = _permissionService.getPermissionStatus();

    setState(() {
      _isLoading = false;
    });

    // If all permissions are granted, proceed automatically
    if (_permissionStatus['allRequired'] == true) {
      widget.onPermissionsGranted();
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isLoading = true;
    });

    final granted = await _permissionService.requestAllPermissions();
    await _checkPermissions();

    if (granted) {
      widget.onPermissionsGranted();
    } else {
      _showPermissionDeniedDialog();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          'Permissions requises',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'SwipeClean a besoin de ces permissions pour fonctionner correctement. Vous pouvez les accorder dans les paramètres de l\'application.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Plus tard',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _permissionService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            child: Text(
              'Paramètres',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 40),
              Expanded(
                child: _buildPermissionsList(),
              ),
              _buildActionButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(
            Icons.security,
            size: 60,
            color: AppConstants.primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Permissions requises',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'SwipeClean a besoin de quelques permissions pour organiser vos photos en toute sécurité.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsList() {
    return Column(
      children: [
        _PermissionItem(
          icon: Icons.photo_library,
          title: 'Accès aux photos',
          description: 'Pour afficher et organiser vos photos',
          isGranted: _permissionStatus['photos'] ?? false,
          onTap: () => _permissionService.requestPhotosPermission().then((_) => _checkPermissions()),
        ),
        const SizedBox(height: 16),
        _PermissionItem(
          icon: Icons.folder,
          title: 'Accès au stockage',
          description: 'Pour créer et gérer les dossiers d\'albums',
          isGranted: _permissionStatus['storage'] ?? false,
          onTap: () => _permissionService.requestStoragePermission().then((_) => _checkPermissions()),
        ),
        const SizedBox(height: 16),
        if (_permissionStatus['manageExternalStorage'] != null)
          _PermissionItem(
            icon: Icons.storage,
            title: 'Gestion des fichiers',
            description: 'Pour déplacer les photos entre les dossiers',
            isGranted: _permissionStatus['manageExternalStorage'] ?? false,
            isOptional: true,
            onTap: () => _permissionService.requestManageExternalStoragePermission().then((_) => _checkPermissions()),
          ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(
            color: AppConstants.primaryColor,
          ),
        ),
      );
    }

    if (_permissionStatus['allRequired'] == true) {
      return Container(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onPermissionsGranted,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.swipeRightColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Continuer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _requestAllPermissions,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'Accorder les permissions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final bool isOptional;
  final VoidCallback onTap;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    this.isOptional = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isGranted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGranted 
                ? AppConstants.swipeRightColor.withOpacity(0.5)
                : isOptional
                    ? AppConstants.swipeDownColor.withOpacity(0.3)
                    : AppConstants.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isGranted 
                    ? AppConstants.swipeRightColor 
                    : isOptional
                        ? AppConstants.swipeDownColor
                        : AppConstants.primaryColor).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isGranted 
                    ? AppConstants.swipeRightColor 
                    : isOptional
                        ? AppConstants.swipeDownColor
                        : AppConstants.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isOptional) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConstants.swipeDownColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Optionnel',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppConstants.swipeDownColor,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              isGranted ? Icons.check_circle : Icons.circle_outlined,
              color: isGranted 
                  ? AppConstants.swipeRightColor 
                  : Colors.white38,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}