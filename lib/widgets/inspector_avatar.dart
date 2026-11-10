import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:road_sense/state/app_state.dart';
import 'package:road_sense/theme/app_theme.dart';

/// Reusable Inspector Avatar Preset model
class InspectorAvatarPreset {
  final String id;
  final String name;
  final String role;
  final String? assetPath;
  final String? networkUrl;
  final Color themeColor;

  const InspectorAvatarPreset({
    required this.id,
    required this.name,
    required this.role,
    this.assetPath,
    this.networkUrl,
    required this.themeColor,
  });
}

/// Available presets for municipal road inspectors
const List<InspectorAvatarPreset> kInspectorPresets = [
  InspectorAvatarPreset(
    id: 'default_abir',
    name: 'Abir',
    role: 'Bangladesh Public Works Inspector (Vest & Cap)',
    assetPath: 'assets/images/inspector_avatar.png',
    themeColor: Color(0xFF09495C),
  ),
  InspectorAvatarPreset(
    id: 'marcus_vance',
    name: 'Marcus Vance',
    role: 'Highway Safety & Asphalt Supervisor',
    networkUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=240&auto=format&fit=crop&q=80',
    themeColor: Color(0xFF16A34A),
  ),
  InspectorAvatarPreset(
    id: 'elena_rostova',
    name: 'Elena Rostova',
    role: 'GIS Defect & Pavement Analyst',
    networkUrl:
        'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=240&auto=format&fit=crop&q=80',
    themeColor: Color(0xFF0284C7),
  ),
  InspectorAvatarPreset(
    id: 'david_miller',
    name: 'David Miller',
    role: 'Road Crew Maintenance Lead',
    networkUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=240&auto=format&fit=crop&q=80',
    themeColor: Color(0xFFD97706),
  ),
  InspectorAvatarPreset(
    id: 'priya_sharma',
    name: 'Priya Sharma',
    role: 'Civil Infrastructure Inspector',
    networkUrl:
        'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=240&auto=format&fit=crop&q=80',
    themeColor: Color(0xFF7C3AED),
  ),
  InspectorAvatarPreset(
    id: 'carlos_mendez',
    name: 'Carlos Mendez',
    role: 'Fleet & Night Inspection Lead',
    networkUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=240&auto=format&fit=crop&q=80',
    themeColor: Color(0xFFDC2626),
  ),
];

/// Universal Inspector Avatar widget connected to [AppState]
class InspectorAvatar extends StatelessWidget {
  final double radius;
  final bool isSquare;
  final double borderRadius;
  final bool showOnlineBadge;
  final bool showEditBadge;
  final VoidCallback? onTap;

  const InspectorAvatar({
    super.key,
    this.radius = 20,
    this.isSquare = false,
    this.borderRadius = 14,
    this.showOnlineBadge = false,
    this.showEditBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final double diameter = radius * 2;

        Widget imageWidget;

        if (state.customAvatarBytes != null &&
            state.customAvatarBytes!.isNotEmpty) {
          imageWidget = Image.memory(
            state.customAvatarBytes!,
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallback(state, diameter),
          );
        } else if (state.customAvatarUrl != null &&
            state.customAvatarUrl!.isNotEmpty) {
          imageWidget = Image.network(
            state.customAvatarUrl!,
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallback(state, diameter),
          );
        } else if (state.customInitials != null &&
            state.customInitials!.isNotEmpty) {
          imageWidget = Container(
            width: diameter,
            height: diameter,
            color: state.customAvatarColor ?? AppTheme.primaryTeal,
            child: Center(
              child: Text(
                state.customInitials!,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: radius * 0.75,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        } else {
          imageWidget = Image.asset(
            state.inspectorAvatarAsset,
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallback(state, diameter),
          );
        }

        Widget content = isSquare
            ? ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: imageWidget,
              )
            : ClipOval(child: imageWidget);

        return GestureDetector(
          onTap: onTap ?? () => showChangeInspectorPhotoModal(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius:
                      isSquare ? BorderRadius.circular(borderRadius) : null,
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: content,
              ),

              // Online status indicator dot (Screenshot 4)
              if (showOnlineBadge)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: radius > 25 ? 16 : 10,
                    height: radius > 25 ? 16 : 10,
                    decoration: BoxDecoration(
                      color: state.isOnDuty
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.2),
                    ),
                  ),
                ),

              // Edit / Camera button badge
              if (showEditBadge)
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallback(AppState state, double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      color: AppTheme.primaryTeal,
      child: Center(
        child: Text(
          state.inspectorName.isNotEmpty ? state.inspectorName[0] : 'A',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.8,
          ),
        ),
      ),
    );
  }
}

/// Interactive modal to change inspector profile photo
Future<void> showChangeInspectorPhotoModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ChangePhotoBottomSheet(),
  );
}

class _ChangePhotoBottomSheet extends StatefulWidget {
  const _ChangePhotoBottomSheet();

  @override
  State<_ChangePhotoBottomSheet> createState() =>
      _ChangePhotoBottomSheetState();
}

class _ChangePhotoBottomSheetState extends State<_ChangePhotoBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _initialsController =
      TextEditingController(text: 'AB');
  Color _selectedColor = const Color(0xFF09495C);
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _initialsController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      setState(() => _isUploading = true);
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final Uint8List bytes = await pickedFile.readAsBytes();
        final ext = pickedFile.name.contains('.')
            ? pickedFile.name.split('.').last.toLowerCase()
            : 'png';

        // Set locally for immediate responsiveness
        AppState.instance.setInspectorAvatarBytes(bytes);

        // Upload and persist to Oakwood municipal backend server
        final serverSuccess =
            await AppState.instance.uploadAvatarToBackend(bytes, ext);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      serverSuccess
                          ? 'Photo loaded from computer & saved to backend server!'
                          : 'Photo loaded from computer into inspector profile!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF09495C),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load photo: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlueAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_circle_rounded,
                    color: Color(0xFF09495C),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Change Inspector Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${state.inspectorName} • ${state.shiftId}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppTheme.primaryTeal,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.upload_file_rounded, size: 18),
                  text: 'Upload',
                ),
                Tab(
                  icon: Icon(Icons.palette_outlined, size: 18),
                  text: 'Presets',
                ),
                Tab(
                  icon: Icon(Icons.link_rounded, size: 18),
                  text: 'Web URL',
                ),
                Tab(
                  icon: Icon(Icons.badge_outlined, size: 18),
                  text: 'Monogram',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUploadTab(context, state),
                _buildPresetsTab(context, state),
                _buildUrlTab(context, state),
                _buildMonogramTab(context, state),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Reset button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    state.resetInspectorAvatar();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Photo restored to default Bangladesh Public Works Inspector.'),
                        backgroundColor: Color(0xFF09495C),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Reset to Default'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Primary feature: Upload any photo from user device / files
  Widget _buildUploadTab(BuildContext context, AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Backend Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: state.isBackendConnected
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: state.isBackendConnected
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: state.isBackendConnected
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF64748B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.isBackendConnected
                        ? 'Backend Server: Connected & Persisting to Disk (Port 8080)'
                        : 'Backend Server: Local Memory Active (Syncing...)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: state.isBackendConnected
                          ? const Color(0xFF166534)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Hero Upload Card
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _isUploading
                  ? null
                  : () => _pickAndUploadPhoto(ImageSource.gallery),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEEF5FD), Color(0xFFE0EDFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF09495C).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFF09495C),
                        shape: BoxShape.circle,
                      ),
                      child: _isUploading
                          ? const Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.computer_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Choose Any Picture from Your Computer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF09495C),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Opens your Windows file explorer to select any photo (PNG, JPEG, WebP) from Pictures, Downloads, or Desktop.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () => _pickAndUploadPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.folder_open_rounded, size: 19),
                      label: const Text('Browse Computer Files'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF09495C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Secondary Camera capture option
          OutlinedButton.icon(
            onPressed: _isUploading
                ? null
                : () => _pickAndUploadPhoto(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_rounded, size: 20),
            label: const Text('Take Photo with Camera'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF09495C),
              side: const BorderSide(color: Color(0xFF09495C), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // If custom photo is already uploaded, show current status
          if (state.customAvatarBytes != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      state.customAvatarBytes!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom Photo Active',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF166534),
                          ),
                        ),
                        Text(
                          'Displayed on all screens and inspection logs.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFDC2626)),
                    tooltip: 'Remove photo',
                    onPressed: () {
                      state.resetInspectorAvatar();
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetsTab(BuildContext context, AppState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: kInspectorPresets.length,
      itemBuilder: (context, index) {
        final preset = kInspectorPresets[index];
        final bool isSelected = (preset.assetPath != null &&
                state.inspectorAvatarAsset == preset.assetPath &&
                state.customAvatarBytes == null &&
                state.customAvatarUrl == null &&
                state.customInitials == null) ||
            (preset.networkUrl != null &&
                state.customAvatarUrl == preset.networkUrl &&
                state.customAvatarBytes == null);

        return Card(
          elevation: isSelected ? 2 : 0,
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryTeal : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          child: InkWell(
            onTap: () {
              if (preset.assetPath != null) {
                state.setInspectorAvatarAsset(preset.assetPath!);
              } else if (preset.networkUrl != null) {
                state.setInspectorAvatarUrl(preset.networkUrl!);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Selected ${preset.name} as inspector photo.'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.primaryTeal,
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: preset.assetPath != null
                        ? Image.asset(
                            preset.assetPath!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            preset.networkUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: preset.themeColor,
                              child: Center(
                                child: Text(
                                  preset.name[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset.role,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUrlTab(BuildContext context, AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Image Web URL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Paste any public photo URL or municipal intranet headshot link.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'https://example.com/inspector.jpg',
              prefixIcon: const Icon(Icons.link_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () => _urlController.clear(),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF09495C),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final url = _urlController.text.trim();
                if (url.isNotEmpty) {
                  state.setInspectorAvatarUrl(url);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Custom inspector photo applied!'),
                      backgroundColor: Color(0xFF09495C),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Apply Custom Photo URL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonogramTab(BuildContext context, AppState state) {
    final colors = [
      const Color(0xFF09495C),
      const Color(0xFF16A34A),
      const Color(0xFF0284C7),
      const Color(0xFFD97706),
      const Color(0xFF7C3AED),
      const Color(0xFFDC2626),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inspector Monogram',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use standard initials with official municipal division colors.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _initialsController.text.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _initialsController,
                  maxLength: 3,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Initials (1-3 chars)',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Choose Division Badge Color',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: colors.map((col) {
              final isChosen = _selectedColor == col;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = col),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: col,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isChosen ? Colors.black : Colors.white,
                      width: isChosen ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: isChosen
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final txt = _initialsController.text.trim();
                if (txt.isNotEmpty) {
                  state.setInspectorInitials(txt.toUpperCase(), _selectedColor);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inspector monogram applied!'),
                      backgroundColor: Color(0xFF09495C),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply Monogram',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
