import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import 'computer_difficulty.dart';
import '../../utils/app_theme.dart';
import '../../widgets/category_card.dart';

class CategoryScreen extends StatelessWidget {
  final bool isForComputer;
  const CategoryScreen({super.key, required this.isForComputer});

  static const categories = [
    'General',
    'History',
    'Science',
    'Math',
    'Computers',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isForComputer ? 'Vs Computer' : 'Play Solo'),
      ),
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
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.accentColor.withOpacity(0.05),
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
                          'Choose a Category',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        Text(
                          isForComputer 
                              ? 'Select a category to challenge the computer'
                              : 'Select a category to test your knowledge',
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
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isForComputer ? Icons.computer_outlined : Icons.person_outlined,
                      size: 32,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            
            Text(
              'Categories',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),

            ...categories.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                child: CategoryCard(
                  category: cat,
                  onTap: () {
                    if (isForComputer) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ComputerDifficulty(category: cat),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(category: cat),
                        ),
                      );
                    }
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
