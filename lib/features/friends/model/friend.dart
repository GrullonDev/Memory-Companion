import 'package:flutter/material.dart';

enum FriendStatus { online, inGame, offline }

class Friend {
  const Friend({
    required this.initials,
    required this.name,
    required this.status,
    required this.avatarColor,
    required this.onAvatarColor,
  });

  final String initials;
  final String name;
  final FriendStatus status;
  final Color avatarColor;
  final Color onAvatarColor;
}
