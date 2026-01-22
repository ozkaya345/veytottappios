import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../presentation/widgets/buttons/app_button.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Hoş geldiniz'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.55, 1.0],
                  colors: [
                    Colors.black,
                    Color.alphaBlend(
                      primary.withValues(alpha: 0.35),
                      Colors.black,
                    ),
                    primary.withValues(alpha: 0.22),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 0,
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: primary.withValues(alpha: 0.45)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/images/home_logo.png',
                              height: 74,
                              fit: BoxFit.contain,
                              errorBuilder: (context, _, __) => const SizedBox(
                                height: 74,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Devam etmek için giriş yapın veya yeni hesap oluşturun.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Giriş',
                            leading: const Icon(Icons.login_rounded),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            fullWidth: true,
                            height: 56,
                            onPressed: () {
                              Navigator.of(context).pushNamed(AppRoutes.login);
                            },
                          ),
                          const SizedBox(height: 12),
                          SecondaryButton(
                            label: 'Kaydol',
                            leading: const Icon(Icons.person_add_alt_1_rounded),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            fullWidth: true,
                            height: 56,
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.register,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
