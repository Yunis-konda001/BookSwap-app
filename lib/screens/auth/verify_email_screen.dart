import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
              'Please verify your email',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'We sent a verification email to ${auth.currentUser?.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await auth.currentUser?.sendEmailVerification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification email sent')),
                    );
                  }
                },
                child: const Text('Resend Email'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await auth.currentUser?.reload();
                // The auth state will automatically update
              },
              child: const Text('I\'ve verified my email'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => auth.signOut(),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}