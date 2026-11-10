import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_sense/config/gemini_config.dart';
import 'package:road_sense/config/osm_config.dart';
import 'package:road_sense/services/gemini_road_service.dart';
import 'package:road_sense/state/app_state.dart';
import 'package:road_sense/widgets/inspector_avatar.dart';

/// Screen representing Inspector Profile, Fleet Vehicle assignment, and Shift Settings.
/// Matches Screenshot 4 (Inspector Shift & Settings) with 100% pixel-perfect fidelity.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final appState = AppState.instance;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 12),
                  _buildInspectorProfileCard(context, appState),
                  const SizedBox(height: 12),
                  _buildCurrentVehicleCard(context, appState),
                  const SizedBox(height: 12),
                  _GeminiIntegrationCard(appState: appState),
                  const SizedBox(height: 12),
                  _OsmIntegrationCard(appState: appState),
                  const SizedBox(height: 12),
                  _buildShiftAssistantSettingsCard(context, appState),
                  const SizedBox(height: 16),
                  _buildShiftActionButton(context, appState),
                  const SizedBox(height: 14),
                  _buildSupportFooter(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Top Header: RoadSense Logo + "RoadSense PW", "Oakwood Public Works", Inspector Avatar
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo + App Name + PW badge
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/roadsense_logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF09495C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.radar_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'RoadSense',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0C3848),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Bangladesh Public Works',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const InspectorAvatar(
            radius: 20,
          ),
        ],
      ),
    );
  }

  /// Card 1: Inspector Profile (Avatar with online indicator dot, Name, Title, Shift ID)
  Widget _buildInspectorProfileCard(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Inspector avatar with bottom-right status dot and change photo badge
            const InspectorAvatar(
              radius: 33,
              isSquare: true,
              borderRadius: 14,
              showOnlineBadge: true,
              showEditBadge: true,
            ),
            const SizedBox(width: 14),

            // Profile info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appState.inspectorName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: appState.isOnDuty
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: appState.isOnDuty
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF64748B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              appState.isOnDuty ? 'On Duty' : 'Off Duty',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: appState.isOnDuty
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    appState.inspectorTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 16,
                        color: Color(0xFF09495C),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Shift ID: ${appState.shiftId}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF09495C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card 2: Current Vehicle (Truck #14, Ford F-250, GPS Status, Change Vehicle)
  Widget _buildCurrentVehicleCard(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row: Truck icon + "Current Vehicle" + "Change Vehicle" button
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: Color(0xFF09495C),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Current Vehicle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showChangeVehicleDialog(context, appState),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0EDFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Change Vehicle',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF09495C),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Inner subcard
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appState.vehicleName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        appState.vehicleModel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: appState.cameraGpsConnected
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        appState.cameraGpsConnected
                            ? 'Camera & GPS Connected'
                            : 'Camera & GPS Offline',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.verified_outlined,
                        size: 18,
                        color: Color(0xFF09495C),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card 3: Shift Assistant Settings (Switches for Auto-Save, Voice Alerts, Offline Storage)
  Widget _buildShiftAssistantSettingsCard(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Row
            const Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: Color(0xFF09495C),
                ),
                SizedBox(width: 8),
                Text(
                  'Shift Assistant Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Setting 1: Auto-Save Potholes
            _buildSettingRow(
              title: 'Auto-Save Potholes',
              subtitle: 'Automatically logs detected holes without manual tapping',
              value: appState.autoSavePotholes,
              onChanged: (val) => appState.toggleAutoSave(val),
            ),
            const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

            // Setting 2: Voice Alerts
            _buildSettingRow(
              title: 'Voice Alerts',
              subtitle: 'Speaks upcoming severe road hazards over truck speaker',
              value: appState.voiceAlerts,
              onChanged: (val) => appState.toggleVoiceAlerts(val),
            ),
            const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

            // Setting 3: Offline Storage
            _buildSettingRow(
              title: 'Offline Storage',
              subtitle: 'Holds high-res photos on device during weak cell signal',
              value: appState.offlineStorage,
              onChanged: (val) => appState.toggleOfflineStorage(val),
            ),
          ],
        ),
      ),
    );
  }

  /// Individual setting item with pill switch matching reference UI
  Widget _buildSettingRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _PillSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Full width button: End Inspection Shift / Start Inspection Shift
  Widget _buildShiftActionButton(BuildContext context, AppState appState) {
    final isOnDuty = appState.isOnDuty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => _confirmShiftToggle(context, appState),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF09495C),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOnDuty ? Icons.logout_rounded : Icons.login_rounded,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                isOnDuty ? 'End Inspection Shift' : 'Start Inspection Shift',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Footer helper link: "Need Help? Call Oakwood Support (ext. 402)"
  Widget _buildSupportFooter(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: () => _showSupportModal(context),
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.headset_mic_outlined,
                size: 16,
                color: Color(0xFF475569),
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Need Help? Call Bangladesh Public Works Support (Saidpur)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Vehicle selection modal
  void _showChangeVehicleDialog(BuildContext context, AppState appState) {
    final vehicles = [
      {'name': 'Truck #14', 'model': 'Ford F-250 Super Duty', 'tag': 'Active Assignment'},
      {'name': 'Truck #09', 'model': 'Crack Sealer Unit - GMC 3500', 'tag': 'Available'},
      {'name': 'Survey Van #03', 'model': 'Ford Transit LiDAR & 4K Pod', 'tag': 'Available'},
      {'name': 'Utility #22', 'model': 'Chevy Silverado Asphalt Patch', 'tag': 'Maintenance'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Fleet Vehicle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Vehicles equipped with calibrated camera & GPS telemetry',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                ...vehicles.map((v) {
                  final isCurrent = v['name'] == appState.vehicleName;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFFEEF5FD) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent ? const Color(0xFF09495C) : const Color(0xFFE2E8F0),
                        width: isCurrent ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.local_shipping_outlined,
                        color: isCurrent ? const Color(0xFF09495C) : const Color(0xFF64748B),
                      ),
                      title: Text(
                        v['name']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? const Color(0xFF09495C) : const Color(0xFF0F172A),
                        ),
                      ),
                      subtitle: Text(
                        v['model']!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.check_circle, color: Color(0xFF09495C))
                          : Text(
                              v['tag']!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                      onTap: () {
                        appState.changeVehicle(v['name']!, v['model']!);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF09495C),
                            content: Text('Switched to ${v['name']} (${v['model']})'),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shift toggle confirmation
  void _confirmShiftToggle(BuildContext context, AppState appState) {
    if (appState.isOnDuty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'End Inspection Shift?',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0C3848)),
          ),
          content: Text(
            'You have logged ${appState.potholesFound} potholes across ${appState.roadsCheckedKm.toStringAsFixed(0)} km today.\n\nYour shift data will be finalized and synced with Bangladesh Public Works headquarters.',
            style: const TextStyle(color: Color(0xFF475569), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                appState.toggleDuty(false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF09495C),
                    content: Text('Shift #PW-4820 ended. Excellent work today, Abir!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF09495C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('End Shift', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else {
      appState.toggleDuty(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          content: Text('Shift started on ${appState.vehicleName}! Safe driving, Abir.'),
        ),
      );
    }
  }

  /// Support sheet
  void _showSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent_rounded, size: 44, color: Color(0xFF09495C)),
              const SizedBox(height: 12),
              const Text(
                'Bangladesh Public Works Dispatch Support',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'For live fleet emergencies, radio issues, or hazard escalation:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.phone_outlined, color: Color(0xFF09495C)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dispatch Desk: (555) 019-4820 (ext. 402)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF09495C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Pill Switch widget matching the screenshot's exact proportions and dark teal aesthetic
class _PillSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PillSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF09495C) : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gemini Multimodal AI Engine Card for Road Condition Evaluation.
/// Displays active API Key, selected model, connectivity status,
/// and live API ping test.
class _GeminiIntegrationCard extends StatefulWidget {
  final AppState appState;

  const _GeminiIntegrationCard({required this.appState});

  @override
  State<_GeminiIntegrationCard> createState() => _GeminiIntegrationCardState();
}

class _GeminiIntegrationCardState extends State<_GeminiIntegrationCard> {
  bool _showKey = false;
  bool _isTesting = false;
  String? _testMessage;
  bool? _testSuccess;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ $label copied to clipboard!'),
        backgroundColor: const Color(0xFF09495C),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _testGeminiApi() async {
    setState(() {
      _isTesting = true;
      _testMessage = null;
    });

    final res = await GeminiRoadService.instance.testConnection();

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testSuccess = res['success'] == true;
      _testMessage = res['message'] as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Sparkle Icon + Title + Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gemini Road Condition Engine',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Multimodal AI • Condition: Alright or Not Alright',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF16A34A)),
                      SizedBox(width: 3),
                      Text(
                        'Ready',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // API Key Box
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Google Gemini API Key',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _showKey ? GeminiConfig.apiKey : GeminiConfig.maskedApiKey,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showKey ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () => setState(() => _showKey = !_showKey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: _showKey ? 'Mask Key' : 'Reveal Key',
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                    onPressed: () => _copyToClipboard(GeminiConfig.apiKey, 'Gemini API Key'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Copy Key',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Models Row
            const Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _ScopeChip(label: GeminiConfig.primaryModel, desc: 'Primary Vision'),
                _ScopeChip(label: GeminiConfig.advancedModel, desc: 'Advanced'),
              ],
            ),

            if (_testMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _testSuccess == true
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _testSuccess == true
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      size: 16,
                      color: _testSuccess == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _testSuccess == true ? const Color(0xFF166534) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isTesting ? null : _testGeminiApi,
                icon: _isTesting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF09495C)),
                      )
                    : const Icon(Icons.network_check_rounded, size: 16),
                label: Text(
                  _isTesting ? 'Pinging Gemini API...' : 'Test Gemini API Key',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
      ),
    );
  }
}

/// OpenStreetMap (OSM) Integration Card for Public Works Profile Screen.
/// Displays OAuth 2.0 Client ID & Client Secret, connection status,
/// active permissions, live test connection, and defect auto-sync switch.
class _OsmIntegrationCard extends StatefulWidget {
  final AppState appState;

  const _OsmIntegrationCard({required this.appState});

  @override
  State<_OsmIntegrationCard> createState() => _OsmIntegrationCardState();
}

class _OsmIntegrationCardState extends State<_OsmIntegrationCard> {
  bool _showSecret = false;
  bool _liveGeoDataSync = true;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ $label copied to clipboard!'),
        backgroundColor: const Color(0xFF09495C),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showOsmEndpointsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.public_rounded, color: Color(0xFF0284C7), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OpenStreetMap OAuth 2.0 Endpoints',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Public Works Inspection Specification',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildEndpointRow('Authorization URL', OsmConfig.authUrl),
            const SizedBox(height: 10),
            _buildEndpointRow('Token URL', OsmConfig.tokenUrl),
            const SizedBox(height: 10),
            _buildEndpointRow('API Base URL', OsmConfig.apiBase),
            const SizedBox(height: 10),
            _buildEndpointRow('Redirect URI', OsmConfig.redirectUri),
            const SizedBox(height: 10),
            _buildEndpointRow(
              'Active Geo-BBox',
              'Saidpur, Rangpur [88.88°E, 25.75°N to 88.93°E, 25.80°N]',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF09495C)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Synced hazards are dispatched to openstreetmap.org/api/0.6/notes with [RoadSense PW] tags.',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF09495C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndpointRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
            onPressed: () => _copyToClipboard(value, label),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState;
    final testResult = state.lastOsmTestResult;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: OSM Icon + Title + Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.public_rounded,
                    size: 20,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OpenStreetMap (OSM)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Public Works Geo-Data & Hazard Sync',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.isOsmConnected
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: state.isOsmConnected
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: state.isOsmConnected
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        state.isOsmConnected ? 'OAuth 2.0 Live' : 'Disconnected',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: state.isOsmConnected
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Credentials Tile 1: Client ID
            _buildCredentialTile(
              label: 'OAuth 2.0 Client ID',
              value: OsmConfig.clientId,
              masked: false,
              onCopy: () => _copyToClipboard(OsmConfig.clientId, 'Client ID'),
            ),
            const SizedBox(height: 8),

            // Credentials Tile 2: Client Secret
            _buildCredentialTile(
              label: 'OAuth 2.0 Client Secret',
              value: _showSecret ? OsmConfig.clientSecret : OsmConfig.maskedSecret,
              masked: !_showSecret,
              onToggleVisibility: () => setState(() => _showSecret = !_showSecret),
              onCopy: () => _copyToClipboard(OsmConfig.clientSecret, 'Client Secret'),
            ),
            const SizedBox(height: 12),

            // Scopes Chips Row
            const Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _ScopeChip(label: 'read_prefs', desc: 'Profile'),
                _ScopeChip(label: 'write_api', desc: 'Map Data'),
                _ScopeChip(label: 'write_notes', desc: 'Hazards'),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14),

            // Setting 1: Auto-Sync Defects to OSM Notes
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Sync Defects to OSM Notes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Publishes severe potholes directly to OpenStreetMap Notes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                _PillSwitch(
                  value: state.isOsmAutoSync,
                  onChanged: (val) => state.toggleOsmAutoSync(val),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Setting 2: Regional Map Geo-Data Sync
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Regional Map Geo-Data Sync',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Queries Saidpur road network & live community notes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                _PillSwitch(
                  value: _liveGeoDataSync,
                  onChanged: (val) {
                    setState(() => _liveGeoDataSync = val);
                    if (val) state.fetchRegionalOsmNotes();
                  },
                ),
              ],
            ),

            // Test Result Banner (if tested)
            if (testResult != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: testResult.success ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: testResult.success ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      testResult.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      size: 16,
                      color: testResult.success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        testResult.success
                            ? 'Verified with OSM API (${testResult.latencyMs}ms) • OAuth Credentials Valid'
                            : testResult.message,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: testResult.success ? const Color(0xFF166534) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            // Actions Row: Test Connection & Endpoints Info
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isTestingOsm
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final res = await state.testOsmConnection();
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                backgroundColor: res.success
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                                duration: const Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                    icon: state.isTestingOsm
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF09495C)),
                          )
                        : const Icon(Icons.network_check_rounded, size: 16),
                    label: Text(
                      state.isTestingOsm ? 'Testing...' : 'Test Connection',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF09495C),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: () => _showOsmEndpointsModal(context),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  tooltip: 'OAuth 2.0 Endpoints',
                  style: const ButtonStyle(
                    side: WidgetStatePropertyAll(BorderSide(color: Color(0xFFCBD5E1))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialTile({
    required String label,
    required String value,
    required bool masked,
    VoidCallback? onToggleVisibility,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onToggleVisibility != null)
            IconButton(
              icon: Icon(
                masked ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: const Color(0xFF64748B),
              ),
              onPressed: onToggleVisibility,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: masked ? 'Reveal Secret' : 'Mask Secret',
            ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
            onPressed: onCopy,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final String desc;

  const _ScopeChip({required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              color: Color(0xFF09495C),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($desc)',
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
