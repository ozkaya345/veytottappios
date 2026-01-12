import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../data/services/firebase_bootstrap.dart';
import '../../core/navigation/app_routes.dart';

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

      future.then((_) {
        if (!completer.isCompleted) completer.complete();
      }).catchError((_) {
        if (!completer.isCompleted) completer.complete();
      }).whenComplete(() {
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

    bool isSignedIn = false;
    try {
      isSignedIn =
          Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      isSignedIn = false;
    }

    Navigator.of(
      context,
    ).pushReplacementNamed(isSignedIn ? AppRoutes.home : AppRoutes.login);
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
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
