import 'package:flutter/material.dart';
import 'quiz_vs_computer.dart';
import '../../utils/app_theme.dart';

class ComputerDifficulty extends StatelessWidget {
  final String category;
  const ComputerDifficulty({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    const levels = [
      {'name': 'Easy', 'icon': Icons.sentiment_satisfied_outlined, 'color': AppTheme.successColor},
      {'name': 'Medium', 'icon': Icons.sentiment_neutral_outlined, 'color': AppTheme.warningColor},
      {'name': 'Hard', 'icon': Icons.sentiment_very_dissatisfied_outlined, 'color': AppTheme.errorColor},
    ];
    
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.getCategoryColor(category).withOpacity(0.1),
                    AppTheme.getCategoryColor(category).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Difficulty',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        Text(
                          'Choose how challenging you want the computer to be',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    decoration: BoxDecoration(
                      color: AppTheme.getCategoryColor(category).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppTheme.getCategoryIcon(category),
                      size: 32,
                      color: AppTheme.getCategoryColor(category),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            
            Text(
              'Difficulty Levels',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),

            ...levels.map((level) {
              final lvl = level['name'] as String;
              final icon = level['icon'] as IconData;
              final color = level['color'] as Color;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                child: Card(
                  elevation: AppTheme.elevationLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizVsComputer(
                            category: category,
                            difficulty: lvl,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingLarge),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.1),
                            color.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingMedium),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                            ),
                            child: Icon(
                              icon,
                              size: AppTheme.iconSizeLarge,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lvl,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lvl == 'Easy'
                                      ? 'Good for beginners'
                                      : lvl == 'Medium'
                                          ? 'For intermediate players'
                                          : 'For expert players',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: color,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
