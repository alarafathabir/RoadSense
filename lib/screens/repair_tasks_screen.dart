import 'package:flutter/material.dart';
import 'package:road_sense/state/app_state.dart';
import 'package:road_sense/widgets/inspector_avatar.dart';

/// Screen representing municipal road repair tasks, budget tracking, and crew dispatch.
/// Matches Screenshot 2 (Repair Tasks) with 100% pixel-perfect fidelity.
class RepairTasksScreen extends StatefulWidget {
  const RepairTasksScreen({super.key});

  @override
  State<RepairTasksScreen> createState() => _RepairTasksScreenState();
}

class _RepairTasksScreenState extends State<RepairTasksScreen> {
  int _selectedTab = 0; // 0: To Do, 1: Done
  bool _showAnalyticsDetails = true;

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final appState = AppState.instance;
        final pendingTasks = appState.pendingTasks;
        final completedTasks = appState.completedTasks;
        final activeList = _selectedTab == 0 ? pendingTasks : completedTasks;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 12),
                        _buildBudgetCard(appState),
                        const SizedBox(height: 16),
                        _buildSegmentedFilter(pendingTasks.length, completedTasks.length),
                        const SizedBox(height: 16),
                        _buildTaskList(activeList, isDoneTab: _selectedTab == 1),
                        const SizedBox(height: 16),
                        _buildAddNewTaskButton(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Top Header: "Repair Tasks", "Oakwood Public Works", Inspector Avatar
  Widget _buildHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repair Tasks',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0C3848),
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Bangladesh Public Works',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          InspectorAvatar(
            radius: 20,
          ),
        ],
      ),
    );
  }

  /// Monthly Budget Card matching reference specifications with Advanced Analytics Dashboard
  Widget _buildBudgetCard(AppState appState) {
    final spentRatio = appState.budgetSpentRatio.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF5FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2ECF8), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title + Crews Active pill badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Budget',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0C3848),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2EBE4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${appState.activeCrews} Crews Active',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0E5B4D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Number Row: ৳42,500 spent of ৳60,000
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '৳${_formatNumber(appState.monthlyBudgetSpent)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0C3848),
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  'spent of ৳${_formatNumber(appState.monthlyBudgetTotal)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5B6B82),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE8F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: spentRatio,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF09495C),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Advanced Analytics Toggle Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 16, color: Color(0xFF09495C)),
                    SizedBox(width: 6),
                    Text(
                      'Cost Breakdown & Savings',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0C3848),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _showAnalyticsDetails = !_showAnalyticsDetails),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFECFB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showAnalyticsDetails ? 'Hide' : 'View',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF09495C),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _showAnalyticsDetails
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: const Color(0xFF09495C),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Expandable Analytics Section
            if (_showAnalyticsDetails) ...[
              const SizedBox(height: 12),

              // Multi-color Material Allocation Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 48,
                        child: Container(color: const Color(0xFF09495C)),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: 32,
                        child: Container(color: const Color(0xFF0D9488)),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: 20,
                        child: Container(color: const Color(0xFFD97706)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 3 Material Component Cards: Asphalt (48%), Labor (32%), Equipment (20%)
              Row(
                children: [
                  _buildCostComponentChip(
                    label: 'Asphalt & Mix',
                    amount: '৳${_formatNumber(appState.asphaltCost)}',
                    percentage: '48%',
                    color: const Color(0xFF09495C),
                    icon: Icons.layers_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildCostComponentChip(
                    label: 'Labor & Crews',
                    amount: '৳${_formatNumber(appState.laborCost)}',
                    percentage: '32%',
                    color: const Color(0xFF0D9488),
                    icon: Icons.engineering_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildCostComponentChip(
                    label: 'Equipment',
                    amount: '৳${_formatNumber(appState.equipmentCost)}',
                    percentage: '20%',
                    color: const Color(0xFFD97706),
                    icon: Icons.precision_manufacturing_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Proactive Savings Highlight Box (বেঁচে যাওয়া অর্থ)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F7F0), Color(0xFFD1F2E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA3E3CA), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.savings_outlined, size: 16, color: Color(0xFF0E5B4D)),
                            SizedBox(width: 6),
                            Text(
                              'Proactive Cost Savings',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0E5B4D),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E5B4D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${appState.reactiveCostMultiplier}x ROI (${appState.proactiveSavingsPct}% Saved)',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '+৳${_formatNumber(appState.proactiveSavings)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0E5B4D),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'saved this month',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF136E5D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Early defect patching (৳${_formatNumber(appState.monthlyBudgetSpent)}) prevented reactive full-depth pavement failures (৳${_formatNumber(appState.estimatedReactiveCost)} avoided).',
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF155E50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Helper chip for material/labor/equipment cost component
  Widget _buildCostComponentChip({
    required String label,
    required String amount,
    required String percentage,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2ECF8), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                percentage,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Segmented pill tabs: "To Do (3)" and "Done (24)"
  Widget _buildSegmentedFilter(int pendingCount, int doneCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFDFECFB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: _selectedTab == 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'To Do ($pendingCount)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w600,
                      color: _selectedTab == 0 ? const Color(0xFF0C3848) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: _selectedTab == 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Done ($doneCount)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w600,
                      color: _selectedTab == 1 ? const Color(0xFF0C3848) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// List of tasks (To Do or Done)
  Widget _buildTaskList(List<RepairTask> tasks, {required bool isDoneTab}) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(
                isDoneTab ? Icons.assignment_turned_in_outlined : Icons.task_alt_outlined,
                size: 48,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 12),
              Text(
                isDoneTab ? 'No completed tasks yet' : 'All repair tasks cleared!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(context, task, isDone: isDoneTab);
      },
    );
  }

  /// Single Task Card item
  Widget _buildTaskCard(BuildContext context, RepairTask task, {required bool isDone}) {
    final isUrgent = task.priority.toUpperCase() == 'URGENT';
    final isScheduled = task.priority.toUpperCase() == 'SCHEDULED';

    Color badgeBg;
    Color badgeTextColor;
    String badgeText;

    if (isDone) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF166534);
      badgeText = 'COMPLETED';
    } else if (isUrgent) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeTextColor = const Color(0xFFDC2626);
      badgeText = 'URGENT';
    } else if (isScheduled) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFB45309);
      badgeText = 'SCHEDULED';
    } else {
      badgeBg = const Color(0xFFE0EDFF);
      badgeTextColor = const Color(0xFF1E40AF);
      badgeText = 'ROUTINE';
    }

    return Container(
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
          // Header Row: Title + Priority Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Location Row
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF09495C),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Location: ${task.location}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Button
          if (isDone)
            _buildDoneActionButton(context, task)
          else if (isUrgent)
            _buildUrgentSendCrewButton(context, task)
          else
            _buildDetailsButton(context, task),
        ],
      ),
    );
  }

  /// Full width dark teal button: Send Repair Crew (for Urgent card)
  Widget _buildUrgentSendCrewButton(BuildContext context, RepairTask task) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          AppState.instance.sendRepairCrew(task.id, 'Crew #4 (Active Dispatch)');
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF09495C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Crew #4 dispatched to ${task.location}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Send Repair Crew',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Full width soft blue button: Details (for Scheduled / Routine cards)
  Widget _buildDetailsButton(BuildContext context, RepairTask task) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () => _showTaskDetailsModal(context, task),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDEECFB),
          foregroundColor: const Color(0xFF09495C),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF09495C)),
            SizedBox(width: 8),
            Text(
              'Details',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF09495C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Full width action button for Completed tasks in the Done tab
  Widget _buildDoneActionButton(BuildContext context, RepairTask task) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: () => _showTaskDetailsModal(context, task),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Work Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 44,
          child: TextButton.icon(
            onPressed: () {
              AppState.instance.toggleTaskDone(task.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF09495C),
                  content: Text('Reopened task "${task.title}" to active list.'),
                ),
              );
            },
            icon: const Icon(Icons.replay_rounded, size: 16, color: Color(0xFF09495C)),
            label: const Text(
              'Reopen',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF09495C),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Full width bottom button: "+ + Add New Task"
  Widget _buildAddNewTaskButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => _showAddNewTaskDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF09495C),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+ + Add New Task',
                style: TextStyle(
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

  /// Shows Task Details modal sheet with breakdown, material requirements, and crew scheduling
  void _showTaskDetailsModal(BuildContext context, RepairTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: task.priority == 'URGENT'
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.priority,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: task.priority == 'URGENT'
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Location & Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.location_on_outlined, 'Location', task.location),
                        const Divider(height: 16, color: Color(0xFFE2E8F0)),
                        _buildDetailRow(Icons.calendar_today_outlined, 'Scheduled', task.scheduledDate),
                        const Divider(height: 16, color: Color(0xFFE2E8F0)),
                        _buildDetailRow(Icons.groups_outlined, 'Assigned Crew', task.assignedCrew),
                        if (task.notes.isNotEmpty) ...[
                          const Divider(height: 16, color: Color(0xFFE2E8F0)),
                          _buildDetailRow(Icons.notes_rounded, 'Work Order Notes', task.notes),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Material Requirements Section
                  const Text(
                    'Material & Equipment Requirements',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRequirementItem('Cold-pour Mastic Asphalt Emulsion (35 gal)'),
                  _buildRequirementItem('Pneumatic Tamper & Plate Compactor'),
                  _buildRequirementItem('Traffic Safety Cones & High-Vis Arrow Board'),
                  _buildRequirementItem('Standard Road Crew Safety Signage (MUTCD)'),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              AppState.instance.sendRepairCrew(task.id, 'Crew #1 (Crack Sealing)');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF09495C),
                                  content: Text('Crew #1 dispatched to ${task.location}!'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF09495C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Dispatch Crew',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              AppState.instance.toggleTaskDone(task.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF16A34A),
                                  content: Text('Marked "${task.title}" as completed!'),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF09495C)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              task.isDone ? 'Mark Incomplete' : 'Mark Completed',
                              style: const TextStyle(
                                color: Color(0xFF09495C),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF09495C)),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog to add a new repair task
  void _showAddNewTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    String selectedPriority = 'URGENT';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Create New Repair Task',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0C3848),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        hintText: 'e.g., Park Ave Pothole Repair',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location / Cross Street',
                        hintText: 'e.g., Park Ave & 9th St',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Priority Level:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['URGENT', 'SCHEDULED', 'ROUTINE'].map((priority) {
                        final isSel = selectedPriority == priority;
                        Color pColor;
                        if (priority == 'URGENT') {
                          pColor = const Color(0xFFDC2626);
                        } else if (priority == 'SCHEDULED') {
                          pColor = const Color(0xFFB45309);
                        } else {
                          pColor = const Color(0xFF1E40AF);
                        }

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => selectedPriority = priority),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? pColor : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                priority,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSel ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Work Order Notes (Optional)',
                        hintText: 'Dimensions, asphalt mix type, lane closure info',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final location = locationController.text.trim();
                    if (title.isEmpty || location.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter title and location')),
                      );
                      return;
                    }

                    AppState.instance.addRepairTask(
                      title,
                      location,
                      selectedPriority,
                      notes: notesController.text.trim(),
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF09495C),
                        content: Text('New task "$title" created successfully!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF09495C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
