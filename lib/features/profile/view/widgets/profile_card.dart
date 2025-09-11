import 'package:flutter/material.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileCard extends StatelessWidget {
  final User? user;

  const ProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Palette.primary.withAlpha(30),
              border: Border.all(color: Palette.primary, width: 3),
            ),
            child:
                user?.photoURL != null
                    ? ClipOval(
                      child: Image.network(
                        user!.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.person,
                              size: 40,
                              color: Palette.primary,
                            ),
                      ),
                    )
                    : const Icon(
                      Icons.person,
                      size: 40,
                      color: Palette.primary,
                    ),
          ),
          const SizedBox(height: 12),

          // User Info with StreamBuilder for real-time updates
          StreamBuilder<User?>(
            stream: authService.value.authStateChanges,
            builder: (context, snapshot) {
              final currentUser = snapshot.data;

              if (currentUser == null) {
                return const Text(
                  'Not signed in',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                );
              }

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: authService.value.getUserDocument(currentUser.uid),
                builder: (context, userDocSnapshot) {
                  String displayName = 'Loading...';

                  if (userDocSnapshot.connectionState == ConnectionState.done) {
                    if (userDocSnapshot.hasData &&
                        userDocSnapshot.data!.exists &&
                        userDocSnapshot.data!.data() != null) {
                      final userData = userDocSnapshot.data!.data()!;
                      displayName =
                          userData['name'] ??
                          currentUser.displayName ??
                          currentUser.email?.split('@')[0] ??
                          'User';
                    } else {
                      displayName =
                          currentUser.displayName ??
                          currentUser.email?.split('@')[0] ??
                          'User';
                    }
                  }

                  return Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  );
                },
              );
            },
          ),

          // Email display
          if (user?.email != null) ...[
            const SizedBox(height: 4),
            Text(
              user!.email!,
              style: const TextStyle(fontSize: 14, color: Palette.subtitle),
            ),
          ],
        ],
      ),
    );
  }
}
