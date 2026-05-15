import 'package:flutter/material.dart';
import 'dart:convert';
import '../utils/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final double radius;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.username,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('data:image')) {
        try {
          final base64String = avatarUrl!.split(',')[1];
          final bytes = base64Decode(base64String);
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (e) {
          print('Error decoding base64 avatar: $e');
        }
      } else {
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(avatarUrl!),
          onBackgroundImageError: (exception, stackTrace) {
            print('Error loading network avatar: $exception');
          },
        );
      }
    }

    return CircleAvatar(
      backgroundColor: AppTheme.primaryColor,
      radius: radius,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppTheme.textLight,
          fontSize: radius * 0.85,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
