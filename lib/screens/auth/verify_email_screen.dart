import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Check verification status when screen loads
    _checkEmailVerified();
    // Set up periodic checking every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerifiedSilently();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    setState(() => _isLoading = true);
    try {
      // Force reload the user from Firebase
      final authService = context.read<AuthService>();
      await authService.reloadUser();
      
      // Get the updated user
      final user = authService.currentUser;
      
      if (user?.emailVerified == true) {
        // Email is verified - show success and let StreamBuilder handle navigation
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully! Welcome to BookSwap!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // The StreamBuilder in main.dart will automatically navigate to MainNav
      } else {
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Email not verified yet. Please check your inbox and click the verification link.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(content: Text('Error checking verification: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkEmailVerifiedSilently() async {
    try {
      // Force reload the user from Firebase
      final authService = context.read<AuthService>();
      await authService.reloadUser();
      
      // Get the updated user
      final user = authService.currentUser;
      
      if (user?.emailVerified == true) {
        // Email is verified - cancel timer and let StreamBuilder handle navigation
        _timer?.cancel();
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Email verified! Redirecting...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Silent check - don't show errors
      // Silent verification check failed
    }
  }

  Future<void> _resendVerification() async {
    try {
      final authService = context.read<AuthService>();
      await authService.sendVerification();
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          TextButton(
            onPressed: () => context.read<AuthService>().signOut(),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      kToolbarHeight - 48,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            const Icon(
              Icons.email_outlined,
              size: 80,
              color: Color(0xFFFFC107),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We sent a verification email to:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Please check your inbox and click the verification link to continue.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkEmailVerified,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('I\'ve Verified My Email'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resendVerification,
              child: const Text('Resend Verification Email'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}