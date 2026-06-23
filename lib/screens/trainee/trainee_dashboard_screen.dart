import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/coach_data_repository.dart';
import '../../models/meal.dart';
import '../../models/menu_type.dart';
import '../../models/weight_entry.dart';
import '../../models/workout.dart';
import 'menu/trainee_menu_screen.dart';
import 'workout/trainee_workout_screen.dart';

class TraineeDashboardScreen extends StatefulWidget {
  final String traineeId;

  const TraineeDashboardScreen({
    super.key,
    required this.traineeId,
  });

  @override
  State<TraineeDashboardScreen> createState() => _TraineeDashboardScreenState();
}

class _TraineeDashboardScreenState extends State<TraineeDashboardScreen> {
  final CoachDataRepository _dataRepository = CoachDataRepository.instance;

  List<Meal> currentMeals = [];
  List<Workout> workouts = [];
  List<WeightEntry> weightHistory = [];
  bool isLoading = true;

  String traineeName = '';
  String traineeGoal = '';
  int? traineeAge;
  double? traineeHeight;

  double? currentWeight;
  double? targetWeight;
  double? startingWeight;

  MenuType _getCurrentMenuType() {
    final int weekday = DateTime.now().weekday;

    if (weekday == DateTime.friday || weekday == DateTime.saturday) {
      return MenuType.weekend;
    }

    return MenuType.weekday;
  }

  String get currentMenuLabel {
    final menuType = _getCurrentMenuType();
    return menuType == MenuType.weekday ? 'אמצע שבוע' : 'סופ״ש';
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final menuType = _getCurrentMenuType();
    final profile = await _dataRepository.getProfile(widget.traineeId);
    final loadedMeals =
        await _dataRepository.getMeals(widget.traineeId, menuType);
    final loadedWorkouts = await _dataRepository.getWorkouts(widget.traineeId);

    setState(() {
      currentMeals = loadedMeals;
      workouts = loadedWorkouts;
      weightHistory = profile.weightHistory;

      traineeName = profile.name;
      traineeGoal = profile.goal;
      traineeAge = profile.age;
      traineeHeight = profile.height;
      currentWeight = profile.currentWeight;
      targetWeight = profile.targetWeight;
      startingWeight = profile.startingWeight;
      isLoading = false;
    });
  }

  double get totalCalories {
    double sum = 0;
    for (final meal in currentMeals) {
      sum += meal.totalCalories;
    }
    return sum;
  }

  double get totalProtein {
    double sum = 0;
    for (final meal in currentMeals) {
      sum += meal.totalProtein;
    }
    return sum;
  }

  int get totalExercises {
    if (workouts.isEmpty) {
      return 0;
    }
    return workouts.first.exercises.length;
  }

  Workout? get featuredWorkout {
    if (workouts.isEmpty) {
      return null;
    }
    return workouts.first;
  }

  Meal? get firstMeal {
    if (currentMeals.isEmpty) {
      return null;
    }
    return currentMeals.first;
  }

  bool get hasProgressData {
    return currentWeight != null &&
        targetWeight != null &&
        startingWeight != null &&
        currentWeight! > 0 &&
        targetWeight! > 0 &&
        startingWeight! > 0 &&
        startingWeight! != targetWeight!;
  }

  double get progressPercent {
    if (!hasProgressData) {
      return 0;
    }

    final start = startingWeight!;
    final current = currentWeight!;
    final target = targetWeight!;

    if (start > target) {
      final total = start - target;
      final done = start - current;
      if (total <= 0) return 0;
      return (done / total).clamp(0, 1);
    } else {
      final total = target - start;
      final done = current - start;
      if (total <= 0) return 0;
      return (done / total).clamp(0, 1);
    }
  }

  double get remainingWeight {
    if (!hasProgressData) {
      return 0;
    }
    return (currentWeight! - targetWeight!).abs();
  }

  String get motivationText {
    if (!hasProgressData) {
      return 'כל צעד קטן שאת עושה נחשב.';
    }

    final percent = progressPercent;

    if (percent >= 1) {
      return 'מדהים, הגעת ליעד שלך. עכשיו שומרים על ההישג.';
    } else if (percent >= 0.75) {
      return 'את ממש קרובה ליעד שלך. תמשיכי בקצב שלך.';
    } else if (percent >= 0.5) {
      return 'חצי דרך זה הישג רציני. את מתקדמת יפה.';
    } else if (percent >= 0.25) {
      return 'יש כבר התקדמות אמיתית. ממשיכים בעקביות.';
    } else {
      return 'התחלות קטנות בונות שינוי גדול לאורך זמן.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMenuType = _getCurrentMenuType();
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            _buildBackground(theme),
            SafeArea(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 18),
                    Text(
                      traineeName.trim().isEmpty ? 'היי 👋' : 'היי $traineeName 👋',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'הדשבורד שלך',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'התפריט שמוצג עכשיו: $currentMenuLabel',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildHeroCard(theme),
                    const SizedBox(height: 16),
                    _buildProfileCard(theme),
                    const SizedBox(height: 16),
                    _buildSummaryStatsRow(theme),
                    const SizedBox(height: 16),
                    _buildProgressCard(theme),
                    const SizedBox(height: 16),
                    _buildWeightGraphCard(theme),
                    const SizedBox(height: 16),
                    _buildMotivationCard(theme),
                    const SizedBox(height: 24),
                    _buildSectionTitle(theme, 'גישה מהירה'),
                    const SizedBox(height: 14),
                    _buildQuickActions(context, currentMenuType, theme),
                    const SizedBox(height: 24),
                    _buildSectionTitle(theme, 'מבט מהיר'),
                    const SizedBox(height: 14),
                    _buildMenuPreviewCard(context, currentMenuType, theme),
                    const SizedBox(height: 16),
                    _buildWorkoutPreviewCard(context, theme),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_forward_ios),
        ),
      ],
    );
  }

  Widget _buildBackground(ThemeData theme) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8E1),
              borderRadius: BorderRadius.circular(110),
            ),
          ),
        ),
        Positioned(
          bottom: -70,
          left: -50,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EE),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            const Color(0xFFFFB3A7),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.favorite_outline,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 12),
          const Text(
            'כל מה שצריך במקום אחד',
            style: TextStyle(
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            traineeGoal.trim().isEmpty
                ? 'תפריט, אימונים והתקדמות — הכל מסודר ונגיש'
                : 'המטרה שלך: $traineeGoal',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    return _buildSoftContainer(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            theme,
            title: 'פרופיל אישי',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          if (traineeName.trim().isNotEmpty)
            _buildProfileRow('שם', traineeName),
          if (traineeAge != null)
            _buildProfileRow('גיל', traineeAge.toString()),
          if (traineeHeight != null)
            _buildProfileRow('גובה', '${traineeHeight!.toStringAsFixed(0)} ס״מ'),
          if (traineeGoal.trim().isNotEmpty)
            _buildProfileRow('מטרה', traineeGoal),
          if (traineeName.trim().isEmpty &&
              traineeAge == null &&
              traineeHeight == null &&
              traineeGoal.trim().isEmpty)
            const Text(
              'עדיין לא הוזנו פרטי מתאמן',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            theme,
            title: 'קלוריות',
            value: totalCalories.toStringAsFixed(0),
            icon: Icons.local_fire_department_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            theme,
            title: 'חלבון',
            value: totalProtein.toStringAsFixed(0),
            icon: Icons.fitness_center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            theme,
            title: 'תרגילים',
            value: totalExercises.toString(),
            icon: Icons.sports_gymnastics,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(
      ThemeData theme, {
        required String title,
        required String value,
        required IconData icon,
      }) {
    return _buildSoftContainer(
      theme,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.primaryColor,
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme) {
    return _buildSoftContainer(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            theme,
            title: 'התקדמות בתהליך',
            icon: Icons.show_chart,
          ),
          const SizedBox(height: 14),
          if (!hasProgressData)
            const Text(
              'עדיין לא הוזנו נתוני משקל על ידי המאמן',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildProgressStat(
                    'משקל נוכחי',
                    '${currentWeight!.toStringAsFixed(1)} ק״ג',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildProgressStat(
                    'משקל יעד',
                    '${targetWeight!.toStringAsFixed(1)} ק״ג',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProgressStat(
              'נותר ליעד',
              '${remainingWeight.toStringAsFixed(1)} ק״ג',
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: LinearProgressIndicator(
                value: progressPercent,
                minHeight: 12,
                backgroundColor: const Color(0xFFFFF1EC),
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(progressPercent * 100).toStringAsFixed(0)}% מהדרך הושלמו',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressStat(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightGraphCard(ThemeData theme) {
    return _buildSoftContainer(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            theme,
            title: 'גרף התקדמות',
            icon: Icons.insights_outlined,
          ),
          const SizedBox(height: 14),
          if (weightHistory.length < 2)
            const Text(
              'צריך לפחות שתי שקילות כדי להציג גרף',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            )
          else ...[
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: WeightGraphPainter(
                  weightHistory: weightHistory,
                  lineColor: theme.primaryColor,
                ),
                size: const Size(double.infinity, 180),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'שקילה ראשונה: ${weightHistory.first.weight.toStringAsFixed(1)} ק״ג',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            Text(
              'שקילה אחרונה: ${weightHistory.last.weight.toStringAsFixed(1)} ק״ג',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMotivationCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              motivationText,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context,
      MenuType currentMenuType,
      ThemeData theme,
      ) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniActionCard(
            theme,
            title: 'תפריט',
            icon: Icons.restaurant,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TraineeMenuScreen(
                    menuType: currentMenuType,
                    traineeId: widget.traineeId,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniActionCard(
            theme,
            title: 'אימונים',
            icon: Icons.fitness_center,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TraineeWorkoutScreen(
                    traineeId: widget.traineeId,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniActionCard(
      ThemeData theme, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildSoftContainer(
        theme,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuPreviewCard(
      BuildContext context,
      MenuType currentMenuType,
      ThemeData theme,
      ) {
    return _buildSoftContainer(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            theme,
            title: 'התפריט שלי',
            icon: Icons.restaurant_menu,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TraineeMenuScreen(
                    menuType: currentMenuType,
                    traineeId: widget.traineeId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (currentMeals.isEmpty)
            const Text(
              'עדיין לא נבנה תפריט',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            )
          else ...[
            Text(
              'מצב נוכחי: $currentMenuLabel',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ארוחה ראשונה: ${firstMeal!.title}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${firstMeal!.items.length} פריטים | '
                  '${firstMeal!.totalCalories.toStringAsFixed(0)} קלוריות',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            ...firstMeal!.items.take(2).map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.foodItem.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutPreviewCard(BuildContext context, ThemeData theme) {
    return _buildSoftContainer(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            theme,
            title: 'האימון שלי',
            icon: Icons.sports_gymnastics,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TraineeWorkoutScreen(
                    traineeId: widget.traineeId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (featuredWorkout == null)
            const Text(
              'עדיין לא נבנה אימון',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            )
          else ...[
            Text(
              featuredWorkout!.title.trim().isEmpty
                  ? 'אימון ללא שם'
                  : featuredWorkout!.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${featuredWorkout!.exercises.length} תרגילים',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            ...featuredWorkout!.exercises.take(2).map(
                  (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exercise.exercise.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      ThemeData theme, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return Row(
      children: [
        Icon(
          icon,
          color: theme.primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: const Text('לצפייה'),
        ),
      ],
    );
  }

  Widget _buildCardHeader(
      ThemeData theme, {
        required String title,
        required IconData icon,
      }) {
    return Row(
      children: [
        Icon(
          icon,
          color: theme.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSoftContainer(
      ThemeData theme, {
        required Widget child,
        EdgeInsetsGeometry padding = const EdgeInsets.all(18),
      }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class WeightGraphPainter extends CustomPainter {
  final List<WeightEntry> weightHistory;
  final Color lineColor;

  WeightGraphPainter({
    required this.weightHistory,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weightHistory.length < 2) return;

    const double leftPadding = 16;
    const double rightPadding = 16;
    const double topPadding = 16;
    const double bottomPadding = 24;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final weights = weightHistory.map((e) => e.weight).toList();
    final minWeight = weights.reduce(math.min);
    final maxWeight = weights.reduce(math.max);

    final safeRange =
    (maxWeight - minWeight).abs() < 0.1 ? 1.0 : maxWeight - minWeight;

    final axisPaint = Paint()
      ..color = const Color(0xFFFFD8CF)
      ..strokeWidth = 1.2;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(leftPadding + chartWidth, topPadding + chartHeight),
      axisPaint,
    );

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );

    final points = <Offset>[];

    for (int i = 0; i < weightHistory.length; i++) {
      final x = leftPadding +
          (weightHistory.length == 1
              ? chartWidth / 2
              : (i / (weightHistory.length - 1)) * chartWidth);

      final normalized = (weightHistory[i].weight - minWeight) / safeRange;
      final y = topPadding + chartHeight - (normalized * chartHeight);

      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    final minTextPainter = TextPainter(
      text: TextSpan(
        text: minWeight.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    final maxTextPainter = TextPainter(
      text: TextSpan(
        text: maxWeight.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    final firstDatePainter = TextPainter(
      text: TextSpan(
        text: weightHistory.first.date.substring(5),
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    final lastDatePainter = TextPainter(
      text: TextSpan(
        text: weightHistory.last.date.substring(5),
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    maxTextPainter.paint(canvas, const Offset(0, 8));
    minTextPainter.paint(canvas, Offset(0, topPadding + chartHeight - 10));

    firstDatePainter.paint(
      canvas,
      Offset(leftPadding - 4, topPadding + chartHeight + 6),
    );

    lastDatePainter.paint(
      canvas,
      Offset(
        leftPadding + chartWidth - lastDatePainter.width,
        topPadding + chartHeight + 6,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant WeightGraphPainter oldDelegate) {
    return oldDelegate.weightHistory != weightHistory ||
        oldDelegate.lineColor != lineColor;
  }
}