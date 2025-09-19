import 'package:flutter/material.dart';

class TimelineEvent {
  final DateTime time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final bool isActive;

  TimelineEvent({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isCompleted,
    this.isActive = false,
  });
}
