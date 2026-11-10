import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:road_sense/screens/field_capture_screen.dart';
import 'package:road_sense/screens/map_screen.dart';
import 'package:road_sense/screens/profile_screen.dart';
import 'package:road_sense/state/app_state.dart';
import 'package:road_sense/theme/app_theme.dart';
import 'package:road_sense/widgets/inspector_avatar.dart';

/// Official RoadSense PW Home Dashboard
/// Matches Public Works specification with live telemetry,
/// vibrant scan action, today's summary metrics, and recent road defects.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(context, state),
                    const SizedBox(height: 22),
                    _buildGreeting(state),
                    const SizedBox(height: 20),
                    _buildHeroCard(context),
                    const SizedBox(height: 26),
                    _buildTodaySummary(context, state),
                    const SizedBox(height: 26),
                    _buildRecentIssuesSection(context, state),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // 1. Header (Equalizer soundwave logo + Inspector Avatar)
  // ---------------------------------------------------------
  Widget _buildHeader(BuildContext context, AppState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: RoadSense Equalizer / Soundwave Icon + "RoadSense" bold text
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEqualizerIcon(),
            const SizedBox(width: 10),
            Text(
              'RoadSense',
              style: GoogleFonts.inter(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        // Right: Inspector Name "Abir" + Avatar Circle
        GestureDetector(
          onTap: () => _openInspectorProfile(context, state),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.inspectorName,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 9),
              const InspectorAvatar(
                radius: 19,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 4-bar vertical soundwave equalizer icon in teal gradient
  Widget _buildEqualizerIcon() {
    return SizedBox(
      height: 24,
      width: 26,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBar(11, const Color(0xFF0C5A70)),
          _buildBar(22, const Color(0xFF09495C)),
          _buildBar(15, const Color(0xFF0E7490)),
          _buildBar(24, const Color(0xFF0C5A70)),
        ],
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  // ---------------------------------------------------------
  // 2. Greeting Section
  // ---------------------------------------------------------
  Widget _buildGreeting(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Good morning, ${state.inspectorName}',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // 3. Vibrant Green Hero Card ("Start Road Scan")
  // ---------------------------------------------------------
  Widget _buildHeroCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FieldCaptureScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.scanGreen,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.scanGreen.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Row(
            children: [
              // Left: rounded square in semi-transparent light green with white Play icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              // Middle column: "Start Road Scan" + "Camera ready"
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start Road Scan',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Camera ready',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFDCFCE7),
                      ),
                    ),
                  ],
                ),
              ),
              // Right: White arrow forward icon
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 4. Today's Summary (2x2 Grid)
  // ---------------------------------------------------------
  Widget _buildTodaySummary(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Summary",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            InkWell(
              onTap: () => _showEditMetricsDialog(context, state),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5FD),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_note_rounded,
                        size: 16, color: Color(0xFF09495C)),
                    const SizedBox(width: 4),
                    Text(
                      'Edit Metrics',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF09495C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Row 1: Roads Checked & Road Health
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context: context,
                state: state,
                label: 'Roads Checked',
                child: Text(
                  '${state.roadsCheckedKm.toInt()} km',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context: context,
                state: state,
                label: 'Road Health',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${state.roadHealthPct}%',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: state.roadHealthPct >= 70
                            ? AppTheme.scanGreen
                            : (state.roadHealthPct >= 40
                                ? const Color(0xFFD97706)
                                : AppTheme.urgentRed),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.roadHealthPct >= 70
                          ? 'Good'
                          : (state.roadHealthPct >= 40 ? 'Fair' : 'Poor'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: state.roadHealthPct >= 70
                            ? AppTheme.scanGreen
                            : (state.roadHealthPct >= 40
                                ? const Color(0xFFD97706)
                                : AppTheme.urgentRed),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Potholes Found & Urgent Fixes
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context: context,
                state: state,
                label: 'Potholes Found',
                child: Text(
                  '${state.potholesFound}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context: context,
                state: state,
                label: 'Urgent Fixes',
                child: Text(
                  '${state.urgentFixes}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.urgentRed,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required AppState state,
    required String label,
    required Widget child,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEditMetricsDialog(context, state),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Icon(Icons.edit_outlined,
                      size: 13, color: Color(0xFF94A3B8)),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }

  void _showEditMetricsDialog(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _EditMetricsModalSheet(state: state),
    );
  }

  // ---------------------------------------------------------
  // 5. Recent Issues Section
  // ---------------------------------------------------------
  Widget _buildRecentIssuesSection(BuildContext context, AppState state) {
    // Shows the active shift issues on Home (dynamically decreases as issues are resolved)
    final issues = state.activeShiftIssues.isNotEmpty
        ? state.activeShiftIssues
        : (state.resolvedIssuesCount == 0 && state.recentIssues.isNotEmpty
            ? state.recentIssues.take(2).toList()
            : <RoadIssue>[]);
    final totalCount = state.totalIssuesCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Recent Issues',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (state.resolvedIssuesCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Text(
                      '${state.resolvedIssuesCount} resolved',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            GestureDetector(
              onTap: () => _openAllIssuesSheet(context, state),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'See All ($totalCount)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0284C7),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (issues.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Clear! No Active Hazards',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'All reported road issues have been inspected and resolved.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...issues.asMap().entries.map((entry) {
            final index = entry.key;
            final issue = entry.value;
            final dotColor = issue.severity.toUpperCase() == 'URGENT'
                ? AppTheme.urgentRed
                : (issue.severity.toUpperCase() == 'MEDIUM'
                    ? const Color(0xFFB45309)
                    : AppTheme.scanGreen);
            return Padding(
              padding:
                  EdgeInsets.only(bottom: index < issues.length - 1 ? 12 : 0),
              child: _buildIssueCard(
                context: context,
                issue: issue,
                dotColor: dotColor,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildIssueCard({
    required BuildContext context,
    required RoadIssue issue,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dot indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          // Title + Subtext
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  issue.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${issue.severity} • ${issue.dimensionDetail}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Soft light blue "View" button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _showDefectModal(context, issue),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlueAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'View',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 6. Defect Modal (Inspection, Coordinates, Crew Dispatch)
  // ---------------------------------------------------------
  void _showDefectModal(BuildContext context, RoadIssue issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
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

              // Title and Severity Badge Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.title,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${issue.location} • Detected ${issue.timestamp}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: issue.severity.toUpperCase() == 'URGENT'
                          ? AppTheme.urgentRedBg
                          : AppTheme.scheduledAmberBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: issue.severity.toUpperCase() == 'URGENT'
                            ? AppTheme.urgentRed.withValues(alpha: 0.3)
                            : AppTheme.scheduledAmber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      issue.severity.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: issue.severity.toUpperCase() == 'URGENT'
                            ? AppTheme.badgeRedText
                            : AppTheme.badgeAmberText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Road Camera Photo / Visualizer
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF0F172A),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/road_camera_feed.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF1E293B),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    // Detection bounding box overlay
                    Positioned(
                      top: 40,
                      left: 60,
                      right: 60,
                      bottom: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: issue.severity.toUpperCase() == 'URGENT'
                                ? AppTheme.urgentRed
                                : Colors.amber,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: issue.severity.toUpperCase() == 'URGENT'
                                  ? AppTheme.urgentRed
                                  : Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${issue.dimensionDetail} [AI 98.4%]',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Telemetry Info Grid
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlueBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildModalInfoRow('GPS Coordinates', issue.coordinates),
                    const Divider(height: 14, color: AppTheme.borderColor),
                    _buildModalInfoRow('Physical Dimension', issue.dimensionDetail),
                    const Divider(height: 14, color: AppTheme.borderColor),
                    _buildModalInfoRow('Inspection Type', issue.isPothole ? 'Pothole (Void Cavity)' : 'Surface Crack (Linear)'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(modalContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text('View on GIS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryTeal,
                        side: const BorderSide(color: AppTheme.primaryTeal),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Dispatch repair crew and register in AppState
                        AppState.instance.addRepairTask(
                          issue.title,
                          issue.location,
                          issue.severity.toUpperCase(),
                          assignedCrew: 'Crew #3 (Immediate Dispatch)',
                          notes: '${issue.dimensionDetail} • ${issue.coordinates}',
                        );
                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.scanGreen,
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Crew #3 dispatched to ${issue.location}!',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Dispatch Crew'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.scanGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final title = issue.title;
                    AppState.instance.resolveIssue(issue.id);
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF09495C),
                        content: Row(
                          children: [
                            const Icon(Icons.verified_rounded,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$title marked as Fixed! Road Health improved to ${AppState.instance.roadHealthPct}%, Urgent Fixes: ${AppState.instance.urgentFixes}.',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      size: 18),
                  label: const Text('Fix & Mark Resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF09495C),
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
      },
    );
  }

  Widget _buildModalInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // 7. "See All (23)" Modal / Bottom Sheet
  // ---------------------------------------------------------
  void _openAllIssuesSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AllIssuesModalSheet(state: state);
      },
    );
  }

  // ---------------------------------------------------------
  // 8. Inspector Profile / Shift Quick Card
  // ---------------------------------------------------------
  void _openInspectorProfile(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0C5A70),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/inspector_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
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
                          state.inspectorName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          state.inspectorTitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreenBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ON DUTY',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.badgeGreenText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildModalInfoRow('Assigned Vehicle', '${state.vehicleName} (${state.vehicleModel})'),
                    const Divider(height: 14, color: AppTheme.borderColor),
                    _buildModalInfoRow('Shift Reference', state.shiftId),
                    const Divider(height: 14, color: AppTheme.borderColor),
                    _buildModalInfoRow('Live Telemetry GPS', state.gpsStatus),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(bottomContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Open Inspector Profile & Shift Settings',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Modal Sheet implementation for "See All (23)" road issues with search and filtering
class _AllIssuesModalSheet extends StatefulWidget {
  final AppState state;
  const _AllIssuesModalSheet({required this.state});

  @override
  State<_AllIssuesModalSheet> createState() => _AllIssuesModalSheetState();
}

class _AllIssuesModalSheetState extends State<_AllIssuesModalSheet> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allIssues = widget.state.recentIssues;
    final filtered = allIssues.where((issue) {
      // Filter by severity
      if (_selectedFilter != 'All' &&
          issue.severity.toLowerCase() != _selectedFilter.toLowerCase()) {
        return false;
      }
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = issue.title.toLowerCase().contains(query);
        final matchLocation = issue.location.toLowerCase().contains(query);
        final matchDim = issue.dimensionDetail.toLowerCase().contains(query);
        if (!matchTitle && !matchLocation && !matchDim) return false;
      }
      return true;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header & handle
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
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
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Road Issues & Defects (${allIssues.length})',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: AppTheme.textSecondary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by road name or hazard type...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.scaffoldBackground,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryTeal),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('All', allIssues.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Urgent', allIssues.where((i) => i.severity.toLowerCase() == 'urgent').length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Medium', allIssues.where((i) => i.severity.toLowerCase() == 'medium').length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Low', allIssues.where((i) => i.severity.toLowerCase() == 'low').length),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderColor),

              // Issues List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No road defects found matching criteria',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          Color dotColor;
                          if (item.severity.toLowerCase() == 'urgent') {
                            dotColor = AppTheme.urgentRed;
                          } else if (item.severity.toLowerCase() == 'medium') {
                            dotColor = const Color(0xFFB45309);
                          } else {
                            dotColor = const Color(0xFF2563EB);
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.severity} • ${item.dimensionDetail} • ${item.location}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _openSingleDefectModal(context, item);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightBlueAccent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'View',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E40AF),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter.toLowerCase() == label.toLowerCase();
    return FilterChip(
      selected: isSelected,
      label: Text('$label ($count)'),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.textSecondary,
      ),
      backgroundColor: AppTheme.scaffoldBackground,
      selectedColor: AppTheme.primaryTeal,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryTeal : AppTheme.borderColor,
        ),
      ),
      onSelected: (val) {
        setState(() => _selectedFilter = label);
      },
    );
  }

  void _openSingleDefectModal(BuildContext context, RoadIssue issue) {
    // Uses the parent's defect modal
    const HomeScreen()._showDefectModal(context, issue);
  }
}

/// Modal Sheet to manually adjust Today's Metrics (Road Health, Potholes, Urgent Fixes, Km)
/// and simulate dynamic issue resolution/addition.
class _EditMetricsModalSheet extends StatefulWidget {
  final AppState state;
  const _EditMetricsModalSheet({required this.state});

  @override
  State<_EditMetricsModalSheet> createState() => _EditMetricsModalSheetState();
}

class _EditMetricsModalSheetState extends State<_EditMetricsModalSheet> {
  late double _roadsChecked;
  late int _roadHealth;
  late int _potholes;
  late int _urgent;

  @override
  void initState() {
    super.initState();
    _roadsChecked = widget.state.roadsCheckedKm;
    _roadHealth = widget.state.roadHealthPct;
    _potholes = widget.state.potholesFound;
    _urgent = widget.state.urgentFixes;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF5FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: Color(0xFF09495C), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Edit Today's Road Metrics",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Manually adjust or simulate defect resolution',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
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
            const SizedBox(height: 18),

            // 1. Road Health Slider & Stepper
            _buildMetricTile(
              title: 'Road Health (%)',
              valueText: '$_roadHealth%',
              color: _roadHealth >= 70
                  ? const Color(0xFF16A34A)
                  : (_roadHealth >= 40
                      ? const Color(0xFFD97706)
                      : const Color(0xFFDC2626)),
              statusBadge: _roadHealth >= 70
                  ? 'Good'
                  : (_roadHealth >= 40 ? 'Fair' : 'Poor'),
              onDecrement: () => setState(
                  () => _roadHealth = (_roadHealth - 2).clamp(0, 100)),
              onIncrement: () => setState(
                  () => _roadHealth = (_roadHealth + 2).clamp(0, 100)),
              child: Slider(
                value: _roadHealth.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                activeColor: _roadHealth >= 70
                    ? const Color(0xFF16A34A)
                    : (_roadHealth >= 40
                        ? const Color(0xFFD97706)
                        : const Color(0xFFDC2626)),
                onChanged: (val) => setState(() => _roadHealth = val.round()),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Potholes Found Stepper
            _buildMetricTile(
              title: 'Potholes Found',
              valueText: '$_potholes',
              color: const Color(0xFF0F172A),
              onDecrement: () =>
                  setState(() => _potholes = (_potholes - 1).clamp(0, 999)),
              onIncrement: () =>
                  setState(() => _potholes = (_potholes + 1).clamp(0, 999)),
            ),
            const SizedBox(height: 12),

            // 3. Urgent Fixes Stepper
            _buildMetricTile(
              title: 'Urgent Fixes Required',
              valueText: '$_urgent',
              color: const Color(0xFFDC2626),
              onDecrement: () =>
                  setState(() => _urgent = (_urgent - 1).clamp(0, 999)),
              onIncrement: () =>
                  setState(() => _urgent = (_urgent + 1).clamp(0, 999)),
            ),
            const SizedBox(height: 12),

            // 4. Roads Checked Stepper
            _buildMetricTile(
              title: 'Roads Checked (km)',
              valueText: '${_roadsChecked.toInt()} km',
              color: const Color(0xFF0F172A),
              onDecrement: () => setState(
                  () => _roadsChecked = (_roadsChecked - 5).clamp(0, 9999)),
              onIncrement: () => setState(
                  () => _roadsChecked = (_roadsChecked + 5).clamp(0, 9999)),
            ),
            const SizedBox(height: 18),

            // Dynamic Action Simulators
            Text(
              'Quick Simulation Actions',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Simulate fixing one issue
                      if (widget.state.recentIssues.isNotEmpty) {
                        final top = widget.state.recentIssues.first;
                        widget.state.resolveIssue(top.id);
                        setState(() {
                          _roadHealth = widget.state.roadHealthPct;
                          _potholes = widget.state.potholesFound;
                          _urgent = widget.state.urgentFixes;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${top.title} Fixed! Road Health improved to $_roadHealth%, Urgent: $_urgent.'),
                            backgroundColor: const Color(0xFF16A34A),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        setState(() {
                          _urgent = (_urgent - 1).clamp(0, 999);
                          _potholes = (_potholes - 1).clamp(0, 999);
                          _roadHealth = (_roadHealth + 3).clamp(0, 100);
                        });
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Fix A Defect',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFF16A34A)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Simulate reporting new defect
                      widget.state.reportIssue(
                        RoadIssue(
                          id: 'sim-${DateTime.now().millisecondsSinceEpoch}',
                          title: 'New Pothole Detected',
                          severity: 'Urgent',
                          dimensionDetail: '8cm deep',
                          location: 'Airport Road near Terminal',
                          coordinates: '25.7680° N, 88.9080° E',
                          timestamp: 'Just now',
                          isPothole: true,
                        ),
                      );
                      setState(() {
                        _roadHealth = widget.state.roadHealthPct;
                        _potholes = widget.state.potholesFound;
                        _urgent = widget.state.urgentFixes;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'New Defect Reported! Road Health: $_roadHealth%, Urgent: $_urgent.'),
                          backgroundColor: const Color(0xFFDC2626),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_alert_rounded, size: 16),
                    label: const Text('New Defect',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Save Button
            ElevatedButton(
              onPressed: () {
                widget.state.updateTelemetry(
                  roadsCheckedKm: _roadsChecked,
                  roadHealthPct: _roadHealth,
                  potholesFound: _potholes,
                  urgentFixes: _urgent,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text("Today's Summary metrics updated successfully!"),
                    backgroundColor: Color(0xFF09495C),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Save & Apply Metrics',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String valueText,
    required Color color,
    String? statusBadge,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
              if (statusBadge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusBadge,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              // Stepper buttons
              InkWell(
                onTap: onDecrement,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Icon(Icons.remove,
                      size: 16, color: Color(0xFF334155)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  valueText,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              InkWell(
                onTap: onIncrement,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Icon(Icons.add,
                      size: 16, color: Color(0xFF334155)),
                ),
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 4),
            child,
          ],
        ],
      ),
    );
  }
}
