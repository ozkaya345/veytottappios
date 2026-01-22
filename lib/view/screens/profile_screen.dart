import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/navigation/app_routes.dart';
import '../../data/services/admin_access_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.reload();
              } catch (_) {}
            },
          ),
        ],
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kullanıcı Bilgileri',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.userChanges(),
                    builder: (context, snapshot) {
                      final u =
                          snapshot.data ?? FirebaseAuth.instance.currentUser;
                      final displayName = u?.displayName?.trim();
                      final email = u?.email?.trim();
                      final photoUrl = u?.photoURL?.trim();
                      final hasPhone2FA =
                          u?.providerData.any((p) => p.providerId == 'phone') ??
                          false;
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage:
                                (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName?.isNotEmpty == true
                                      ? displayName!
                                      : 'İsimsiz Kullanıcı',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (email != null && email.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                _TwoFaBadge(active: hasPhone2FA),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _PillButton(
                    label: 'Ayarlar',
                    height: 56,
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.settings);
                    },
                  ),
                  const SizedBox(height: 12),
                  _PillButton(
                    label: 'Güvenlik',
                    height: 56,
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.security);
                    },
                  ),
                  const SizedBox(height: 12),
                  _PillButton(
                    label: 'Çöp Kutusu',
                    height: 56,
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.trash);
                    },
                  ),
                  const SizedBox(height: 12),
                  _PillButton(
                    label: 'Çıkış Yap',
                    height: 56,
                    onPressed: () async {
                      AdminAccessService.lock();
                      try {
                        await FirebaseAuth.instance.signOut();
                      } catch (_) {}
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.auth,
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onPressed,
    this.height = 56,
  });

  final String label;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final double r = height / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(r),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(r),
              border: Border.all(
                color: primary.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TwoFaBadge extends StatelessWidget {
  const _TwoFaBadge({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bg = active
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final fg = active ? colors.onPrimaryContainer : colors.onSurface;
    final icon = active ? Icons.verified : Icons.shield_outlined;
    final text = active ? '2FA Aktif' : '2FA Pasif';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? colors.primary : colors.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
