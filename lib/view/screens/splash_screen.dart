import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../data/services/firebase_bootstrap.dart';
import '../../core/navigation/app_routes.dart';
import '../../data/services/admin_auth_service.dart';
import '../../data/services/admin_access_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final Completer<void> _precacheCompleter = Completer<void>();
  late final Future<void> _firebaseInitFuture;
  final List<Timer> _timers = <Timer>[];

  @override
  void initState() {
    super.initState();

    _firebaseInitFuture = FirebaseBootstrap.init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPrecache();
    });

    _bootstrapAndNavigate();
  }

  void _startPrecache() {
    if (!mounted || _precacheCompleter.isCompleted) return;

    () async {
      try {
        await Future.wait([
          precacheImage(const AssetImage('assets/images/logo.png'), context),
        ]);
      } catch (_) {
        // Precache başarısız olsa bile akışı bloklamayalım.
      } finally {
        if (!_precacheCompleter.isCompleted) {
          _precacheCompleter.complete();
        }
      }
    }();
  }

  Future<void> _bootstrapAndNavigate() async {
    Future<void> waitOrTimeout(Future<void> future, Duration duration) {
      final completer = Completer<void>();
      final timer = Timer(duration, () {
        if (!completer.isCompleted) completer.complete();
      });
      _timers.add(timer);

      future
          .then((_) {
            if (!completer.isCompleted) completer.complete();
          })
          .catchError((_) {
            if (!completer.isCompleted) completer.complete();
          })
          .whenComplete(() {
            timer.cancel();
          });

      return completer.future;
    }

    Future<void> delayCancelable(Duration duration) {
      final completer = Completer<void>();
      final timer = Timer(duration, () {
        if (!completer.isCompleted) completer.complete();
      });
      _timers.add(timer);
      return completer.future;
    }

    try {
      await Future.wait([
        waitOrTimeout(_firebaseInitFuture, const Duration(seconds: 6)),
        waitOrTimeout(_precacheCompleter.future, const Duration(seconds: 2)),
        delayCancelable(const Duration(seconds: 3)),
      ]);
    } catch (_) {
      await delayCancelable(const Duration(seconds: 3));
    }

    if (!mounted) return;

    if (kIsWeb) {
      final qp = Uri.base.queryParameters;
      final mode = qp['mode'];
      final oobCode = qp['oobCode'];
      if (mode == 'resetPassword' &&
          oobCode != null &&
          oobCode.trim().isNotEmpty) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.resetPassword,
          arguments: oobCode.trim(),
        );
        return;
      }
    }

    // Güvenlik gereği her açılışta şifre ekranı gelsin.
    // Oturum varsa bile otomatik Home'a geçme.
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // signOut başarısız olsa bile login ekranına gidelim.
    }

    // UI düzeyinde admin kilidini her açılışta kapat.
    AdminAccessService.lock();

    // Admin oturumunu da temizle ki yeni şifre her seferinde geçerli olsun.
    try {
      final adminAuth = await AdminAuthService.adminAuth();
      await adminAuth.signOut();
    } catch (_) {
      // ignore
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            final targetWidth = (maxWidth * 0.90).clamp(300.0, 650.0);
            final targetHeight = (maxHeight * 0.90).clamp(300.0, 650.0);

            return Center(
              child: SizedBox(
                width: targetWidth,
                height: targetHeight,
                child: Image.asset(
                  'assets/images/splash.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
