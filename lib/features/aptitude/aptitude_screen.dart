import 'package:flutter/material.dart';
import 'aptitude_service.dart';
import 'aptitude_model.dart';
import '../../utils/app_theme.dart';

class AptitudeScreen extends StatefulWidget {
  const AptitudeScreen({super.key});

  @override
  State<AptitudeScreen> createState() => _AptitudeScreenState();
}

class _AptitudeScreenState extends State<AptitudeScreen> with SingleTickerProviderStateMixin {
  final AptitudeService _aptitudeService = AptitudeService();
  List<AptitudeResult> _results = [];
  bool _isLoading = true;
  bool _isAnalyzing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadAptitudeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAptitudeData() async {
    setState(() => _isLoading = true);
    
    try {
      final uid = _aptitudeService.currentUserId;
      
      final results = await _aptitudeService.fetchAptitudeResults(uid);
      
      if (results.isEmpty) {
        final calculatedResults = await _aptitudeService.calculateAptitude(uid);
        
        setState(() {
          _results = calculatedResults;
          _isLoading = false;
        });
      } else {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
      
      _animationController.forward();
    } catch (e, stackTrace) {
      print('❌ Error loading aptitude data: $e');
      print('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reAnalyze() async {
    setState(() => _isAnalyzing = true);
    
    try {
      final uid = _aptitudeService.currentUserId;
      final results = await _aptitudeService.calculateAptitude(uid);
      
      setState(() {
        _results = results;
        _isAnalyzing = false;
      });
      
      _animationController.reset();
      _animationController.forward();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aptitude analysis updated!'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error re-analyzing: $e');
      setState(() => _isAnalyzing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aptitude Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? _buildEmptyState()
              : _buildResultsList(),
      floatingActionButton: _results.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isAnalyzing ? null : _reAnalyze,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.textLight,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppTheme.textLight,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.refresh_outlined),
              label: Text(_isAnalyzing ? 'Analyzing...' : 'Re-Analyze'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXLarge),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assessment_outlined,
                size: 100,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              'No Aptitude Data Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Play some quizzes to see your aptitude analysis and get personalized career recommendations!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXLarge),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.textLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXLarge,
                  vertical: AppTheme.spacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
              ),
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Start Playing'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      children: [
        _buildSummaryCard(),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: AppTheme.spacingMedium,
              right: AppTheme.spacingMedium,
              top: AppTheme.spacingMedium,
              bottom: 80,
            ),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              return FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      index * 0.1,
                      (index * 0.1) + 0.5,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        index * 0.1,
                        (index * 0.1) + 0.5,
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                  child: _buildCategoryCard(_results[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final strongestCategory = _results.isNotEmpty ? _results.first : null;
    final averageAccuracy = _results.isEmpty
        ? 0.0
        : _results.fold(0.0, (sum, r) => sum + r.accuracy) / _results.length;

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.assessment_outlined,
                color: AppTheme.textLight,
                size: 24,
              ),
              SizedBox(width: AppTheme.spacingSmall),
              Text(
                'Performance Summary',
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Categories',
                '${_results.length}',
                Icons.category_outlined,
              ),
              _buildSummaryItem(
                'Average',
                '${averageAccuracy.toStringAsFixed(1)}%',
                Icons.trending_up_outlined,
              ),
              if (strongestCategory != null)
                _buildSummaryItem(
                  'Strongest',
                  strongestCategory.category,
                  Icons.star_outline,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textLight.withOpacity(0.9), size: 28),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textLight.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(AptitudeResult result) {
    final color = AptitudeResult.getPerformanceColor(result.accuracy);
    final categoryColor = AppTheme.getCategoryColor(result.category);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      elevation: AppTheme.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          gradient: LinearGradient(
            colors: [
              categoryColor.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingSmall),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                        ),
                        child: Icon(
                          AppTheme.getCategoryIcon(result.category),
                          color: categoryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Expanded(
                        child: Text(
                          result.category,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text(
                    result.performanceLevel,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            Row(
              children: [
                const Icon(Icons.bar_chart_outlined, size: 20, color: AppTheme.textSecondary),
                const SizedBox(width: AppTheme.spacingSmall),
                const Text(
                  'Accuracy:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${result.accuracy.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingSmall),
            
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              child: LinearProgressIndicator(
                value: result.accuracy / 100,
                backgroundColor: AppTheme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.quiz_outlined,
                    'Questions',
                    '${result.questionsAttempted}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.timer_outlined,
                    'Avg Time',
                    '${result.averageTime.toStringAsFixed(1)}s',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            const Divider(),
            const SizedBox(height: AppTheme.spacingMedium),
            
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.warningColor),
                SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: Text(
                    'Recommended Career Fields:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            Wrap(
              spacing: AppTheme.spacingSmall,
              runSpacing: AppTheme.spacingSmall,
              children: result.recommendedFields.map((field) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    field,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: AppTheme.spacingSmall),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryColor),
            SizedBox(width: AppTheme.spacingSmall),
            Text('About Aptitude Analysis'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This feature analyzes your quiz performance across different categories and provides:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              const Text('• Accuracy percentage for each subject'),
              const Text('• Average response time'),
              const Text('• Performance level (Excellent/Good/Average)'),
              const Text('• Career field recommendations'),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                'Play more quizzes to get more accurate recommendations!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
