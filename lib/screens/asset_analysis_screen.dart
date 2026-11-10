import 'package:flutter/material.dart';
import 'package:road_sense/theme/app_theme.dart';
import 'package:road_sense/widgets/gradient_button.dart';

class AssetAnalysisScreen extends StatelessWidget {
  final String routeName;
  final int score;
  final String assetId;

  const AssetAnalysisScreen({
    super.key,
    this.routeName = 'Airport Road · Saidpur Lane 1',
    this.score = 94,
    this.assetId = 'HWY-940-02',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSeverityCard(),
                    const SizedBox(height: 16),
                    _buildPriorityIndex(),
                    const SizedBox(height: 16),
                    _buildDeteriorationTrajectory(),
                    const SizedBox(height: 16),
                    _buildRepairCostAnalysis(),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'Integrate with GIS',
                      onPressed: () {},
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.cardBgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Asset Analysis',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'ID: $assetId',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Row(
        children: [
          // Pothole thumbnail
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF1A1F38),
            ),
            clipBehavior: Clip.hardEdge,
            child: CustomPaint(painter: _PotholeThumbnailPainter()),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Severe Pothole',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  routeName,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.alertRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.alertRed.withValues(alpha: 0.4),
                        width: 0.8),
                  ),
                  child: const Text(
                    '98.2% AI CONFIDENCE',
                    style: TextStyle(
                      color: AppTheme.alertRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityIndex() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Row(
        children: [
          // Circular score
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _CircularScorePainter(score: score),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'SCORE',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MAINTENANCE PRIORITY INDEX',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Based on structural damage velocity, local transit volume, and wet-weather hazard forecast.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeteriorationTrajectory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DETERIORATION TRAJECTORY',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'Index Score %',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: CustomPaint(
              painter: _DeteriorationGraphPainter(),
              size: const Size(double.infinity, 100),
            ),
          ),
          const SizedBox(height: 8),
          // X-axis labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _XLabel('Present'),
              _XLabel('+3 Mo.'),
              _XLabel('+6 Mo.'),
              _XLabel('+9 Mo.'),
              _XLabel('+12 Mo.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepairCostAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REPAIR COST ANALYSIS',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 130,
            child: CustomPaint(
              painter: _CostBarChartPainter(),
              size: const Size(double.infinity, 130),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BarLabel(label: 'PROACTIVE', color: AppTheme.sensorGreen),
              _BarLabel(label: 'REACTIVE', color: AppTheme.accentPink),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.sensorGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.sensorGreen.withValues(alpha: 0.2),
                  width: 0.8),
            ),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: 'Early intervention saves an average of '),
                  TextSpan(
                    text: '75% (৳3,600)',
                    style: TextStyle(
                      color: AppTheme.sensorGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: ' per asset.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _XLabel extends StatelessWidget {
  final String text;
  const _XLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
    );
  }
}

class _BarLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _BarLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────

class _PotholeThumbnailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Road surface
    final road = Paint()..color = const Color(0xFF2A3048);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), road);

    // Pothole shape
    final holePaint = Paint()..color = const Color(0xFF0A0D1A);
    final path = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.55),
        width: size.width * 0.55,
        height: size.height * 0.42,
      ));
    canvas.drawPath(path, holePaint);

    // Crack lines
    final crack = Paint()
      ..color = const Color(0xFF1A1F38)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(size.width * 0.35, size.height * 0.35),
        Offset(size.width * 0.15, size.height * 0.2),
        crack);
    canvas.drawLine(
        Offset(size.width * 0.65, size.height * 0.35),
        Offset(size.width * 0.85, size.height * 0.15),
        crack);
    canvas.drawLine(
        Offset(size.width * 0.5, size.height * 0.7),
        Offset(size.width * 0.5, size.height * 0.9),
        crack);

    // AI detection overlay tint
    final overlay = Paint()
      ..color = AppTheme.accentPink.withValues(alpha: 0.12);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlay);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircularScorePainter extends CustomPainter {
  final int score;
  const _CircularScorePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 7.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = AppTheme.divider
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [AppTheme.primaryPurple, AppTheme.accentPink],
        startAngle: 0,
        endAngle: 3.14 * 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.14 / 2; // Start from top
    final sweepAngle = 2 * 3.14159 * score / 100;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DeteriorationGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Y-axis guide lines
    final gridPaint = Paint()
      ..color = AppTheme.divider
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Curve points (declining)
    final points = [
      Offset(0, size.height * 0.1),
      Offset(size.width * 0.2, size.height * 0.22),
      Offset(size.width * 0.4, size.height * 0.38),
      Offset(size.width * 0.6, size.height * 0.58),
      Offset(size.width * 0.8, size.height * 0.75),
      Offset(size.width, size.height * 0.92),
    ];

    // Gradient fill
    final fillPath = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpx = (prev.dx + curr.dx) / 2;
      fillPath.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.alertRed.withValues(alpha: 0.3),
          AppTheme.alertRed.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePath = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpx = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
    }

    final linePaint = Paint()
      ..color = AppTheme.alertRed
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Current position dot
    canvas.drawCircle(
      points[0],
      5,
      Paint()..color = AppTheme.alertRed,
    );
    canvas.drawCircle(
      points[0],
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CostBarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const maxValue = 4800.0;
    const proactive = 1200.0;
    const reactive = 4800.0;

    final barWidth = size.width * 0.18;
    final spacing = size.width * 0.15;
    final centerX = size.width / 2;

    final proX = centerX - spacing / 2 - barWidth;
    final reactX = centerX + spacing / 2;

    // Y-axis grid
    final gridPaint = Paint()
      ..color = AppTheme.divider
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Proactive bar
    final proHeight = (proactive / maxValue) * size.height * 0.85;
    final proRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(proX, size.height - proHeight, barWidth, proHeight),
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
    );
    canvas.drawRRect(
      proRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppTheme.sensorGreen,
            AppTheme.sensorGreen.withValues(alpha: 0.6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(proX, 0, barWidth, size.height)),
    );

    // Reactive bar
    final reactHeight = (reactive / maxValue) * size.height * 0.85;
    final reactRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(reactX, size.height - reactHeight, barWidth, reactHeight),
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
    );
    canvas.drawRRect(
      reactRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppTheme.accentPink,
            AppTheme.accentPink.withValues(alpha: 0.6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(reactX, 0, barWidth, size.height)),
    );

    // Value labels on top of bars
    const textStyle = TextStyle(
      color: AppTheme.textPrimary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );

    _drawText(canvas, '৳1,200', proX + barWidth / 2,
        size.height - proHeight - 18, textStyle);
    _drawText(canvas, '৳4,800', reactX + barWidth / 2,
        size.height - reactHeight - 18, textStyle);
  }

  void _drawText(
      Canvas canvas, String text, double x, double y, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
