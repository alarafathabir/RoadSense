import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:road_sense/config/gemini_config.dart';
import 'package:road_sense/state/app_state.dart';
import 'package:road_sense/theme/app_theme.dart';
import 'package:road_sense/widgets/inspector_avatar.dart';

/// CameraScreen: Real-Time Windshield Camera & AI Hazard Detection
/// Replicates Screenshot 1 with live viewfinder HUD, dynamic scan toggle,
/// defect reporting modal, interactive defect snapshot, and audible sound alerts.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late AnimationController _hazardPulseController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _hazardPulseAnimation;

  // Real Phone Camera hardware streaming controls
  List<CameraDescription> _availableCameras = [];
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isInitializingCamera = false;
  bool _isTakingPicture = false;
  int _selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;
  bool _preferHardwareCamera = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Laser scan line animation
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _scanAnimation = CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    );

    // Glowing live indicator dot pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // Subtle hazard box alert pulse
    _hazardPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _hazardPulseAnimation = CurvedAnimation(
      parent: _hazardPulseController,
      curve: Curves.easeInOut,
    );

    // Automatically initialize hardware phone camera for the viewfinder
    _initHardwareCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      cameraController.dispose();
      if (mounted) setState(() => _isCameraReady = false);
    } else if (state == AppLifecycleState.resumed) {
      _initHardwareCamera(cameraIndex: _selectedCameraIndex);
    }
  }

  /// Initializes the device phone camera (preferring the rear camera for road inspection)
  Future<void> _initHardwareCamera({int cameraIndex = 0}) async {
    if (_isInitializingCamera) return;
    if (mounted) {
      setState(() {
        _isInitializingCamera = true;
      });
    }

    try {
      final cameras = await availableCameras();
      _availableCameras = cameras;
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isCameraReady = false;
            _isInitializingCamera = false;
          });
        }
        return;
      }

      int targetIndex = cameraIndex;
      if (targetIndex >= cameras.length) {
        targetIndex = 0;
      }
      if (cameraIndex == 0) {
        final backIndex = cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        if (backIndex != -1) {
          targetIndex = backIndex;
        }
      }

      await _cameraController?.dispose();
      final controller = CameraController(
        cameras[targetIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _selectedCameraIndex = targetIndex;
        _isCameraReady = true;
        _isInitializingCamera = false;
        _currentFlashMode = controller.value.flashMode;
      });
    } catch (_) {
      // Gracefully fall back to simulated / gallery picker in environments without cameras
      if (mounted) {
        setState(() {
          _isCameraReady = false;
          _isInitializingCamera = false;
        });
      }
    }
  }

  /// Flip between available lenses (Rear road view vs Front selfie/in-cabin view)
  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) return;
    final nextIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    await _initHardwareCamera(cameraIndex: nextIndex);
  }

  /// Toggle torch / flash on the phone camera
  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final nextMode = _currentFlashMode == FlashMode.torch
          ? FlashMode.off
          : FlashMode.torch;
      await _cameraController!.setFlashMode(nextMode);
      if (mounted) setState(() => _currentFlashMode = nextMode);
    } catch (_) {}
  }

  /// Snaps a picture from the live phone camera stream and passes it to Gemini evaluation
  Future<void> _takePictureFromHardwareCamera(AppState appState) async {
    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_isTakingPicture &&
        _preferHardwareCamera) {
      try {
        setState(() => _isTakingPicture = true);
        final XFile photo = await _cameraController!.takePicture();
        final bytes = await photo.readAsBytes();
        appState.setCustomCameraPhoto(bytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Phone camera photo captured! Evaluating road condition with Gemini...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF09495C),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      } catch (_) {
        // Fall back to ImagePicker camera
      } finally {
        if (mounted) {
          setState(() => _isTakingPicture = false);
        }
      }
    }

    // Fallback to system camera / picker
    await _captureDeviceCamera(appState);
  }

  Future<void> _captureDeviceCamera(AppState appState) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        appState.setCustomCameraPhoto(bytes);
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Photo captured! Gemini AI evaluating road condition...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF09495C),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          appState.setCustomCameraPhoto(bytes);
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Photo loaded! Gemini AI evaluating road condition...',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF09495C),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    _hazardPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header (RoadSense PW + Avatar)
                  _buildHeader(context, appState),
                  const SizedBox(height: 16),

                  // 2. Card Header (Live Road Camera + Active Pill)
                  _buildCardHeader(appState),
                  const SizedBox(height: 12),

                  // 2.1 Quick Controls: Camera Feed & AI Detection Toggles + Device Camera Access
                  _buildCameraAccessControlBar(context, appState),
                  const SizedBox(height: 12),

                  // 3. Live Viewfinder Container with AI Overlays
                  _buildViewfinderContainer(context, appState),
                  const SizedBox(height: 16),

                  // 4. Action Buttons (Report Issue + Stop/Start Scan)
                  _buildActionButtons(context, appState),
                  const SizedBox(height: 16),

                  // 4.1 Gemini Multimodal Road Condition Evaluation (Alright or Not Alright)
                  _buildGeminiRoadConditionCard(context, appState),
                  const SizedBox(height: 16),

                  // 4.2 AI Damage & Minimal Cost Prediction Card
                  _buildAiDamageAndCostCard(context, appState),
                  const SizedBox(height: 16),

                  // 5. Sound Alert Card
                  _buildSoundAlertCard(appState),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── 1. Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AppState appState) {
    final canPop = Navigator.canPop(context);

    return Row(
      children: [
        if (canPop) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 8),
        ],

        // RoadSense PW Logo Box
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryTeal.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(7),
          child: Image.asset(
            'assets/images/roadsense_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.radar_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Brand Text & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'RoadSense',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0EDFF),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'PW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF09495C),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Bangladesh Public Works',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Inspector Avatar
        const InspectorAvatar(
          radius: 20,
        ),
      ],
    );
  }

  // ─── 2. Card Header ────────────────────────────────────────────────────────
  Widget _buildCardHeader(AppState appState) {
    final isScanning = appState.isScanning;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Animated glowing green live indicator dot
            _buildGlowingLiveDot(isScanning),
            const SizedBox(width: 8),
            const Text(
              'Live Road Camera',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),

        // Active / Paused Pill Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isScanning
                ? const Color(0xFF036449)
                : const Color(0xFFB45309),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isScanning
                        ? const Color(0xFF036449)
                        : const Color(0xFFB45309))
                    .withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isScanning
                    ? Icons.check_circle_rounded
                    : Icons.pause_circle_filled_rounded,
                color: Colors.white,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                isScanning ? 'Active' : 'Paused',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlowingLiveDot(bool isScanning) {
    if (!isScanning) {
      return Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Color(0xFFB45309),
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 18,
          height: 18,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 10 + (6 * _pulseAnimation.value),
                  height: 10 + (6 * _pulseAnimation.value),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(
                      alpha: 0.35 * (1.0 - (_pulseAnimation.value * 0.4)),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 2.1 Camera Control Bar (Feed & AI Detection Toggles + Device Camera) ──
  Widget _buildCameraAccessControlBar(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 1. Camera Feed Toggle Switch
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    appState.isCameraFeedEnabled
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    size: 18,
                    color: appState.isCameraFeedEnabled
                        ? const Color(0xFF09495C)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Camera Feed',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: appState.isCameraFeedEnabled,
                      activeThumbColor: const Color(0xFF09495C),
                      activeTrackColor:
                          const Color(0xFF09495C).withValues(alpha: 0.35),
                      onChanged: (val) => appState.toggleCameraFeed(val),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // 2. AI Detection Toggle Switch
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.radar_rounded,
                    size: 18,
                    color: appState.isAiDetectionEnabled
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'AI Detection',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: appState.isAiDetectionEnabled,
                      activeThumbColor: const Color(0xFF16A34A),
                      activeTrackColor:
                          const Color(0xFF16A34A).withValues(alpha: 0.35),
                      onChanged: (val) => appState.toggleAiDetection(val),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 12, color: Color(0xFFF1F5F9)),

          // Access Device Camera / Live Photo Button Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _takePictureFromHardwareCamera(appState),
                  icon: const Icon(Icons.photo_camera_rounded, size: 16),
                  label: Text(
                    appState.customCameraPhotoBytes != null
                        ? 'Retake & Evaluate Photo'
                        : 'Access Device Camera',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF09495C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: appState.isEvaluatingWithGemini
                    ? null
                    : () => appState.evaluateCurrentPhotoWithGemini(),
                icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                label: const Text('Gemini Scan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0284C7),
                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (appState.customCameraPhotoBytes != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {
                    appState.setCustomCameraPhoto(null);
                    appState.setCameraSource('windshield');
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  color: const Color(0xFF64748B),
                  tooltip: 'Reset to windshield feed',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── 3. Viewfinder Container ───────────────────────────────────────────────
  Widget _buildViewfinderContainer(BuildContext context, AppState appState) {
    const double viewfinderHeight = 280.0;

    // When Camera Feed is turned OFF
    if (!appState.isCameraFeedEnabled) {
      return Container(
        height: viewfinderHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1120),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF475569)),
                ),
                child: const Icon(
                  Icons.videocam_off_rounded,
                  size: 38,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Camera Feed Paused',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Camera feed is turned off. Toggle switch to resume.',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => appState.toggleCameraFeed(true),
                icon: const Icon(Icons.videocam_rounded, size: 16),
                label: const Text('Turn On Camera Feed',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF09495C),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: viewfinderHeight,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Visual Feed Layer:
          // 1. If user captured a photo frame (frozen snapshot evaluated with Gemini)
          if (appState.customCameraPhotoBytes != null)
            Image.memory(
              appState.customCameraPhotoBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          // 2. Real Phone Camera Hardware Video Stream
          else if (_isCameraReady &&
              _cameraController != null &&
              _cameraController!.value.isInitialized &&
              _preferHardwareCamera)
            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController!.value.previewSize?.height ??
                          constraints.maxWidth,
                      height: _cameraController!.value.previewSize?.width ??
                          constraints.maxHeight,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                );
              },
            )
          // 3. Connecting to Phone Camera loading indicator
          else if (_isInitializingCamera && _preferHardwareCamera)
            Container(
              color: const Color(0xFF0F172A),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF22D3EE),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Starting Phone Camera...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          // 4. Default / Simulation Windshield Feed (runs in emulators, tests & demo)
          else
            Image.asset(
              'assets/images/road_camera_feed.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => _buildFallbackRoadFeed(),
            ),

          // Vignette overlays for top & bottom contrast
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 70,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Overlay Top Left: [camera icon] AI Scanning Road & Phone Cam indicator
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        appState.customCameraPhotoBytes != null
                            ? Icons.photo_camera_rounded
                            : Icons.videocam_rounded,
                        color: const Color(0xFF22D3EE),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        appState.customCameraPhotoBytes != null
                            ? 'Device Camera Live'
                            : 'AI Scanning Road',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isCameraReady &&
                    _preferHardwareCamera &&
                    appState.customCameraPhotoBytes == null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_android_rounded, size: 11, color: Colors.white),
                        SizedBox(width: 3),
                        Text(
                          'Phone Cam',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Overlay Top Right: Quick Phone Camera Controls (Flip, Flash, Mode Toggle)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Switch Lens (Front vs Back)
                  if (_availableCameras.length > 1 || _isCameraReady)
                    InkWell(
                      onTap: _switchCamera,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(
                          Icons.flip_camera_ios_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),

                  // Torch / Flash toggle
                  InkWell(
                    onTap: _toggleFlash,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        _currentFlashMode == FlashMode.torch
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: _currentFlashMode == FlashMode.torch
                            ? const Color(0xFFFACC15)
                            : Colors.white,
                        size: 15,
                      ),
                    ),
                  ),

                  // Mode Toggle (Phone Camera vs Simulation Feed)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _preferHardwareCamera = !_preferHardwareCamera;
                        if (_preferHardwareCamera && !_isCameraReady) {
                          _initHardwareCamera(cameraIndex: _selectedCameraIndex);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        _preferHardwareCamera
                            ? Icons.smartphone_rounded
                            : Icons.desktop_windows_rounded,
                        color: _preferHardwareCamera
                            ? const Color(0xFF22D3EE)
                            : const Color(0xFF94A3B8),
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay Center Top: Hazard Detection status indicator
          Positioned(
            top: 13,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appState.isAiDetectionEnabled
                      ? 'Hazard Detection - Active'
                      : 'AI Detection Paused',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Animated laser scanning line effect (when AI Detection & Scanning active)
          if (appState.isScanning && appState.isAiDetectionEnabled)
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                final topPos = _scanAnimation.value * (viewfinderHeight - 44);
                return Positioned(
                  top: topPos,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2.2,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0x3300E5FF),
                          Color(0xFF00E5FF),
                          Color(0xFF38BDF8),
                          Color(0xFF00E5FF),
                          Color(0x3300E5FF),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.7),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // AI Hazard Detection Overlays (when AI Detection is enabled)
          if (appState.isAiDetectionEnabled)
            Positioned(
              top: 100,
              left: 60,
              right: 60,
              height: 125,
              child: _buildHazardOverlay(context, appState),
            ),

          // Floating Shutter / Resume Button (Center Bottom of Viewfinder)
          Positioned(
            bottom: 38,
            left: 0,
            right: 0,
            child: Center(
              child: appState.customCameraPhotoBytes != null
                  ? ElevatedButton.icon(
                      onPressed: () {
                        appState.setCustomCameraPhoto(null);
                        appState.setCameraSource('windshield');
                      },
                      icon: const Icon(Icons.videocam_rounded, size: 14),
                      label: const Text(
                        'Resume Live Phone Camera',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF036449),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => _takePictureFromHardwareCamera(appState),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.92),
                          border: Border.all(
                            color: const Color(0xFF036449),
                            width: 2.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isTakingPicture
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF036449),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: Color(0xFF036449),
                                size: 22,
                              ),
                      ),
                    ),
            ),
          ),

          // Overlay Bottom HUD Telemetry Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomHudBar(appState),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackRoadFeed() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 44,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Road Viewfinder Feed',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AI Hazard Bounding Box & Cyan Reticle ──────────────────────────────────
  Widget _buildHazardOverlay(BuildContext context, AppState appState) {
    return GestureDetector(
      onTap: () => _showDefectSnapshotModal(context, appState),
      child: AnimatedBuilder(
        animation: _hazardPulseAnimation,
        builder: (context, child) {
          final borderAlpha = 0.85 + (0.15 * _hazardPulseAnimation.value);
          final fillAlpha = 0.20 + (0.08 * _hazardPulseAnimation.value);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Shaded Red Hazard Region
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: fillAlpha),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withValues(alpha: borderAlpha),
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner: [warning] Pothole Detected (High) | Alert
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Pothole Detected (High)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Alert',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Cyan Inner Focus Bounding Box with Corner Bracket Reticles
              Positioned(
                top: 32,
                left: 18,
                right: 18,
                bottom: 12,
                child: CustomPaint(
                  painter: const ReticleCornerPainter(
                    color: Color(0xFF00E5FF),
                    strokeWidth: 2.2,
                    cornerLength: 12.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF00E5FF).withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Text(
                        'POTHOLE DETECTED',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Bottom HUD Bar ────────────────────────────────────────────────────────
  Widget _buildBottomHudBar(AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: [car icon] Vehicle moving • ${appState.vehicleSpeed} km/h
          Row(
            children: [
              const Icon(
                Icons.directions_car_rounded,
                size: 16,
                color: Color(0xFF38BDF8),
              ),
              const SizedBox(width: 6),
              Text(
                'Vehicle moving • ${appState.vehicleSpeed} km/h',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Right: [gps icon] GPS OK
          Row(
            children: [
              const Icon(
                Icons.my_location_rounded,
                size: 14,
                color: Color(0xFF22C55E),
              ),
              const SizedBox(width: 5),
              Text(
                appState.gpsStatus,
                style: const TextStyle(
                  color: Color(0xFF4ADE80),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 4. Action Buttons ─────────────────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context, AppState appState) {
    final isScanning = appState.isScanning;

    return Row(
      children: [
        // Left Button: [error icon] Report Issue (Red)
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _showReportIssueModal(context, appState),
              icon: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Report Issue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Right Button: [stop/play icon] Stop Scan / Start Scan (Teal)
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                appState.toggleScanning();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      appState.isScanning
                          ? 'Road scanning resumed (35 km/h)'
                          : 'Road scanning paused',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: appState.isScanning
                        ? const Color(0xFF036449)
                        : const Color(0xFF09495C),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              icon: Icon(
                isScanning
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                isScanning ? 'Stop Scan' : 'Start Scan',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF09495C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── 3.1 Gemini Multimodal Road Condition Evaluation Card ───────────────────
  Widget _buildGeminiRoadConditionCard(BuildContext context, AppState appState) {
    final eval = appState.currentRoadEvaluation;
    final isEvaluating = appState.isEvaluatingWithGemini;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: eval == null
              ? AppTheme.borderColor
              : (eval.isRoadAlright ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: eval == null
                ? Colors.black.withValues(alpha: 0.03)
                : (eval.isRoadAlright
                    ? const Color(0xFF16A34A).withValues(alpha: 0.08)
                    : const Color(0xFFDC2626).withValues(alpha: 0.08)),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Gemini Badge + Model Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF09495C), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gemini Road Condition Assessment',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Vision API • ${GeminiConfig.maskedApiKey}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5FD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  eval != null ? eval.modelUsed : GeminiConfig.primaryModel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Content body
          if (isEvaluating) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF09495C)),
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Evaluating Road Condition with Gemini AI...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Analyzing pavement surface, potholes, cracks, and safety hazards',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else if (eval != null) ...[
            // Verdict Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: eval.isRoadAlright ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: eval.isRoadAlright ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    eval.isRoadAlright
                        ? Icons.check_circle_rounded
                        : Icons.dangerous_rounded,
                    color: eval.isRoadAlright
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eval.isRoadAlright
                              ? 'ROAD CONDITION IS ALRIGHT ✓'
                              : 'ROAD CONDITION: NOT ALRIGHT ⚠️',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: eval.isRoadAlright
                                ? const Color(0xFF14532D)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          eval.verdict,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: eval.isRoadAlright
                                ? const Color(0xFF166534)
                                : const Color(0xFFB91C1C),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Pavement Quality Score: ${eval.conditionScore}/100 • ${eval.latencyMs}ms',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: eval.isRoadAlright
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Assessment details grid: Defect, Severity, Depth, Area
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildGeminiMetric(
                        'Road Status',
                        eval.isRoadAlright ? 'Alright' : 'Defective',
                        eval.isRoadAlright ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                      Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                      _buildGeminiMetric(
                        'Defect Type',
                        eval.defectType,
                        const Color(0xFF0F172A),
                      ),
                      Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                      _buildGeminiMetric(
                        'Severity',
                        eval.severity,
                        eval.severity.toLowerCase() == 'urgent'
                            ? const Color(0xFFDC2626)
                            : (eval.isRoadAlright ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
                      ),
                    ],
                  ),
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildGeminiMetric(
                        'Est. Depth',
                        eval.depthEstimate,
                        const Color(0xFF334155),
                      ),
                      Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                      _buildGeminiMetric(
                        'Damage Area',
                        eval.damageArea,
                        const Color(0xFF334155),
                      ),
                      Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                      _buildGeminiMetric(
                        'Est. Repair Cost',
                        eval.estimatedCostTaka > 0 ? '৳${eval.estimatedCostTaka}' : '৳0',
                        const Color(0xFF09495C),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Gemini Summary & Explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, size: 20, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      eval.summary,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                if (!eval.isRoadAlright) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        appState.addRepairTask(
                          '${eval.defectType} Hazard (${eval.severity})',
                          'Captured from Camera (${appState.vehicleName})',
                          eval.severity.toUpperCase(),
                          assignedCrew: 'Crew #3 (Immediate)',
                          notes: '${eval.summary} • Est: ৳${eval.estimatedCostTaka}',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ Repair task created for ${eval.defectType}!'),
                            backgroundColor: const Color(0xFF09495C),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_task_rounded, size: 16),
                      label: const Text('Add Task', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF09495C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => appState.evaluateCurrentPhotoWithGemini(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Re-evaluate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF09495C),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Empty state: prompt user to click picture
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    size: 36,
                    color: Color(0xFF09495C),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No Photo Evaluated Yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Click a picture with your phone camera or evaluate the active road feed to check if the road condition is alright.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _captureDeviceCamera(appState),
                          icon: const Icon(Icons.photo_camera_rounded, size: 16),
                          label: const Text(
                            'Click Picture with Camera',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF09495C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => appState.evaluateCurrentPhotoWithGemini(),
                          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                          label: const Text(
                            'Evaluate Active Feed',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF09495C),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeminiMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ─── 4. Action Buttons ───────────────────────────────────────────────────────
  Widget _buildAiDamageAndCostCard(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with AI Icon and Confidence Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF5FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF09495C),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Damage & Cost Prediction',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Computer Vision Structural Assessment',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '98.4% Match',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Damage Metrics (Depth, Dimensions, Structural Severity)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol('Severity', 'Urgent (High)', const Color(0xFFDC2626)),
                Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                _buildMetricCol('Est. Depth', '7.2 cm', const Color(0xFF0F172A)),
                Container(height: 32, width: 1, color: const Color(0xFFE2E8F0)),
                _buildMetricCol('Damage Area', '1.2 m²', const Color(0xFF0F172A)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Predicted Repair Costs in Bangladeshi Taka ৳
          const Text(
            'Estimated Minimal Repair Cost:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // Minimal Quick Patch (Cold Mix)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF5FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Minimal Fix',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Fast',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '৳2,800',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF09495C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Cold Asphalt Patch • 2h',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Full Permanent Resurfacing
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permanent Fix',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '৳5,500',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hot-Mix Bitumen • 1 day',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action dispatch button with minimal cost
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                appState.addRepairTask(
                  'Airport Road Pothole Quick Fix',
                  'Airport Road near BAUST',
                  'URGENT',
                  assignedCrew: 'Crew #2 (Pothole Patching)',
                  notes: 'Minimal Cold Asphalt Patch • Est. Cost: ৳2,800',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Quick Fix Task Dispatched! (Est. Minimal Cost: ৳2,800)'),
                    backgroundColor: Color(0xFF036449),
                  ),
                );
              },
              icon: const Icon(Icons.flash_on_rounded, size: 16),
              label: const Text(
                'Quick Fix Dispatch (৳2,800)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF09495C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── 5. Sound Alert Card ───────────────────────────────────────────────────
  Widget _buildSoundAlertCard(AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left soft light-blue square container with volume icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.volume_up_outlined,
              color: Color(0xFF09495C),
              size: 23,
            ),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sound Alert for Potholes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Beep when damage is detected',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Switch bound to AppState.soundAlertForPotholes
          Switch(
            value: appState.soundAlertForPotholes,
            activeThumbColor: const Color(0xFF09495C),
            activeTrackColor: const Color(0xFF09495C).withValues(alpha: 0.35),
            onChanged: (val) {
              appState.toggleSoundAlert(val);
              if (val) {
                appState.audioBeep();
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── Defect Snapshot Modal (Tapping Viewfinder Bounding Box) ───────────────
  void _showDefectSnapshotModal(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pothole Detected (High Severity)',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Speed: ${appState.vehicleSpeed} km/h • GPS Verified • Camera Front #1',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Metrics row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSnapshotMetric('Est. Depth', '7.2 cm', const Color(0xFFDC2626)),
                    Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                    _buildSnapshotMetric('Est. Width', '48 cm', const Color(0xFF0F172A)),
                    Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                    _buildSnapshotMetric('AI Confidence', '98.4%', const Color(0xFF036449)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Location coordinate pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF09495C)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Airport Road & Sailar Mor • Saidpur Division\n25.7745° N, 88.9012° E',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Predicted Cost Estimation in Taka
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 18, color: Color(0xFF166534)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated Minimal Repair Cost',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF166534),
                            ),
                          ),
                          Text(
                            'Cold-mix bitumen patch & tamping',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '৳2,800',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showReportIssueModal(context, appState,
                            prefilledTitle: 'Airport Road Pothole');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF09495C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Dispatch Repair',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSnapshotMetric(String title, String val, Color valColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          val,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valColor,
          ),
        ),
      ],
    );
  }

  // ─── Comprehensive "Report Road Issue" Modal Dialog ────────────────────────
  void _showReportIssueModal(
    BuildContext context,
    AppState appState, {
    String prefilledTitle = 'Airport Road Pothole',
  }) {
    final titleController = TextEditingController(text: prefilledTitle);
    final dimController = TextEditingController(text: '7cm deep, 48cm wide');
    final locController = TextEditingController(text: 'Airport Road near BAUST');
    String selectedSeverity = 'Urgent';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grab bar
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.report_problem_rounded,
                                color: Color(0xFFB91C1C),
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Report Road Issue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(modalCtx),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFFE2E8F0), height: 16),

                      // Issue Title
                      const Text(
                        'Defect Title',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Airport Road Pothole',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Severity Selector
                      const Text(
                        'Severity Level',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildSeverityChip(
                            label: 'Urgent',
                            color: const Color(0xFFDC2626),
                            isSelected: selectedSeverity == 'Urgent',
                            onTap: () =>
                                setModalState(() => selectedSeverity = 'Urgent'),
                          ),
                          const SizedBox(width: 10),
                          _buildSeverityChip(
                            label: 'Medium',
                            color: const Color(0xFFB45309),
                            isSelected: selectedSeverity == 'Medium',
                            onTap: () =>
                                setModalState(() => selectedSeverity = 'Medium'),
                          ),
                          const SizedBox(width: 10),
                          _buildSeverityChip(
                            label: 'Low',
                            color: const Color(0xFF16A34A),
                            isSelected: selectedSeverity == 'Low',
                            onTap: () =>
                                setModalState(() => selectedSeverity = 'Low'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Dimensions
                      const Text(
                        'Dimensions & Depth',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: dimController,
                        decoration: InputDecoration(
                          hintText: 'e.g. 7cm deep, 45cm wide',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Location notes
                      const Text(
                        'Location & Cross Street',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: locController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Airport Road near BAUST or Sailar Mor',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // GPS Coordinates Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.gps_fixed_rounded,
                                size: 16, color: Color(0xFF09495C)),
                            SizedBox(width: 8),
                            Text(
                              'GPS Lock: 25.7745° N, 88.9012° E (±1.2m)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            final title = titleController.text.trim().isEmpty
                                ? 'Reported Pothole'
                                : titleController.text.trim();
                            final dim = dimController.text.trim().isEmpty
                                ? '7cm deep'
                                : dimController.text.trim();
                            final loc = locController.text.trim().isEmpty
                                ? 'Airport Road near BAUST'
                                : locController.text.trim();

                            final issue = RoadIssue(
                              id: 'issue-${DateTime.now().millisecondsSinceEpoch}',
                              title: title,
                              severity: selectedSeverity,
                              dimensionDetail: dim,
                              location: loc,
                              coordinates: '25.7685° N, 88.9080° E',
                              timestamp: 'Just now',
                              isPothole: title.toLowerCase().contains('pothole') ||
                                  selectedSeverity == 'Urgent',
                            );

                            appState.reportIssue(issue);
                            Navigator.pop(modalCtx);

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Reported "$title" ($selectedSeverity)! Added to Public Works queue.',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF036449),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF09495C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Submit Report',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSeverityChip({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Reticle Corner Painter for Cyan Focus Box ──────────────────────────────
class ReticleCornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  const ReticleCornerPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.cornerLength = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Top-left corner
    canvas.drawLine(const Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, cornerLength), paint);

    // Top-right corner
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-left corner
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom-right corner
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant ReticleCornerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.cornerLength != cornerLength;
  }
}
