import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sjlshs_chronos/features/auth/auth_providers.dart';
import 'package:sjlshs_chronos/features/auth/user_metadata.dart' as user_metadata;

class VerificationInfoScreen extends ConsumerWidget {
  const VerificationInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final userMetadataAsync = ref.watch(userMetadataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Verification'),
        automaticallyImplyLeading: false, // Prevents back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: userMetadataAsync.when(
            data: (userMetadata) {
              if (userMetadata?.isVerified == true) {
                // This should theoretically never be shown due to router redirects
                return _buildVerifiedView(context);
              } else {
                return _buildUnverifiedView(context, user, ref);
              }
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          'Account Verified!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your account has been successfully verified. You now have full access to all features.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            // Navigate to home or dashboard
            GoRouter.of(context).go('/scanner');
          },
          child: const Text('Continue to App'),
        ),
      ],
    );
  }

  Widget _buildUnverifiedView(
      BuildContext context, User? user, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.pending_actions,
          size: 80,
          color: Colors.orange,
        ),
        const SizedBox(height: 24),
        const Text(
          'Account Pending Verification',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your account is currently under review by our administrators. This process typically takes 24-48 hours.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      GoRouter.of(context).go('/login');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out: $e')),
                      );
                    }
                  }
                },
                child: const Text('Sign Out'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Refresh the user data
                  ref.invalidate(userMetadataProvider);
                },
                child: const Text('Check Status'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
