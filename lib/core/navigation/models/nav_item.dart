import 'package:flutter/material.dart';

class NavItem {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavItem({
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

const List<NavItem> navItems = [
  NavItem(
    path: '/home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Home',
  ),
  NavItem(
    path: '/profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: 'Profile',
  ),
  NavItem(
    path: '/messages',
    icon: Icons.email_outlined,
    selectedIcon: Icons.email,
    label: 'Messages',
  ),
];
