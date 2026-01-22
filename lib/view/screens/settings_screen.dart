import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';
import '../../data/services/local_theme_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Ayarlar'),
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
                  stops: const [0.0, 0.4, 0.75, 1.0],
                  colors: [
                    Color.alphaBlend(
                      primary.withValues(alpha: 0.25),
                      Colors.black,
                    ),
                    Color.alphaBlend(
                      primary.withValues(alpha: 0.45),
                      Colors.black,
                    ),
                    Color.alphaBlend(
                      primary.withValues(alpha: 0.60),
                      Colors.black,
                    ),
                    Color.alphaBlend(
                      primary.withValues(alpha: 0.70),
                      Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [_ThemeSection()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tema Seçimi', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _ThemeChoiceChip(label: 'Siyah-Yeşil', variant: ThemeVariant.green),
            _ThemeChoiceChip(label: 'Siyah-Mavi', variant: ThemeVariant.blue),
            _ThemeChoiceChip(label: 'Siyah-Kırmızı', variant: ThemeVariant.red),
            _ThemeChoiceChip(
              label: 'Siyah-Turuncu',
              variant: ThemeVariant.orange,
            ),
            _ThemeChoiceChip(label: 'Siyah-Mor', variant: ThemeVariant.purple),
            _ThemeChoiceChip(label: 'Siyah-Beyaz', variant: ThemeVariant.mono),
          ],
        ),
      ],
    );
  }
}

class _ThemeChoiceChip extends StatelessWidget {
  const _ThemeChoiceChip({required this.label, required this.variant});

  final String label;
  final ThemeVariant variant;

  @override
  Widget build(BuildContext context) {
    final selected = ThemeController.instance.variant == variant;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        if (value) {
          ThemeController.instance.setVariant(variant);
        }
      },
    );
  }
}
