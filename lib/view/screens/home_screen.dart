import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ottapp/l10n/app_localizations.dart';
import '../../core/navigation/app_routes.dart';

class _ProfileMenuIcon extends StatelessWidget {
  const _ProfileMenuIcon({this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
        final url = user?.photoURL?.trim() ?? '';
        final hasUrl = url.isNotEmpty;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.25),
            border: Border.all(
              color: primary.withValues(alpha: 0.60),
              width: 1.2,
            ),
          ),
          child: ClipOval(
            child: hasUrl
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _fallbackIcon;
                    },
                  )
                : _fallbackIcon,
          ),
        );
      },
    );
  }

  Widget get _fallbackIcon =>
      const Center(child: Icon(Icons.person, color: Colors.white));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;

    // Kullanıcı adı veya e-posta mevcutsa üstte gösterelim.
    String? displayName;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final name = user?.displayName?.trim();
      final email = user?.email?.trim();
      displayName = (name != null && name.isNotEmpty)
          ? name
          : ((email != null && email.isNotEmpty) ? email : null);
    } catch (_) {
      displayName = null;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // Başlıklar
                  Text(
                    'Hoş geldiniz',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (displayName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _PillButton(
                          label: 'Durum Ekle',
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.statusAdd);
                          },
                          icon: Icons.add_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _PillButton(
                          label: l10n.personnelTitle,
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.personnel);
                          },
                          icon: Icons.people_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PillButton(
                          label: 'Kod ile Aç',
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.statusOpenCode);
                          },
                          icon: Icons.key,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _PillButton(
                          label: l10n.homeTrackStatus,
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.statusTrackList);
                          },
                          icon: Icons.track_changes,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Align(
            alignment: Alignment(0, 0.6),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.zero,
                child: Image(
                  image: AssetImage('assets/images/logo.png'),
                  height: 260,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed(AppRoutes.profile);
                  },
                  child: const SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(
                      child: IgnorePointer(child: _ProfileMenuIcon(size: 44)),
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

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const double height = 72;
    const double r = height / 2;

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
            // width: double.infinity, // satır içi Expanded ile genişlik zaten doluyor
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
            child: icon == null
                ? Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white.withValues(alpha: 0.9)),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Eski özel overlay ve bölge sınıfları kaldırıldı; yeni tasarım sade.
// _HeaderBar kullanılmıyor; tasarım sadeleştirildi.
