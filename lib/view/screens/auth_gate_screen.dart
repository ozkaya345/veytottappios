import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../presentation/widgets/buttons/app_button.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hoş geldiniz')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: 'Giriş',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.login);
              },
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Kaydol',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.register);
              },
            ),
          ],
        ),
      ),
    );
  }
}
