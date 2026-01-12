import 'package:flutter/material.dart';

/// App-wide reusable button with variants, sizes, and loading state.
///
/// Prefer using typed widgets like [PrimaryButton], [SecondaryButton],
/// [OutlineButtonApp], and [TextActionButton] for clarity.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.loadingIndicatorSize,
    this.fullWidth = false,
    this.expand = false,
    this.height,
  }) : assert(
         label != null || child != null,
         'Provide either a label or a child',
       );

  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final Widget? leading;
  final Widget? trailing;
  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Optional override for loading spinner size (in logical pixels).
  final double? loadingIndicatorSize;

  /// Make button fill the available width.
  final bool fullWidth;

  /// Make button expand to parent's constraints (both width and height).
  final bool expand;

  /// Override button height. When set, it takes precedence over [size].
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool canTap = enabled && !isLoading && onPressed != null;
    final content = _buildContent(context);

    final ButtonStyle style = _buildStyle(theme);

    late final Widget innerButton;
    switch (variant) {
      case AppButtonVariant.primary:
        innerButton = FilledButton(
          onPressed: canTap ? onPressed : null,
          style: style,
          child: content,
        );
      case AppButtonVariant.secondary:
        innerButton = FilledButton.tonal(
          onPressed: canTap ? onPressed : null,
          style: style,
          child: content,
        );
      case AppButtonVariant.outline:
        innerButton = OutlinedButton(
          onPressed: canTap ? onPressed : null,
          style: style,
          child: content,
        );
      case AppButtonVariant.text:
        innerButton = TextButton(
          onPressed: canTap ? onPressed : null,
          style: style,
          child: content,
        );
    }

    if (expand) {
      return SizedBox.expand(child: innerButton);
    }
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: innerButton);
    }
    return innerButton;
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final double spacing = switch (size) {
      AppButtonSize.sm => 8,
      AppButtonSize.md => 10,
      AppButtonSize.lg => 12,
    };

    final Color spinnerColor = switch (variant) {
      AppButtonVariant.primary => cs.onPrimary,
      AppButtonVariant.secondary => cs.onSecondaryContainer,
      AppButtonVariant.outline => cs.primary,
      AppButtonVariant.text => cs.primary,
    };

    if (isLoading) {
      final double spinnerSize =
          loadingIndicatorSize ??
          switch (size) {
            AppButtonSize.sm => 16,
            AppButtonSize.md => 20,
            AppButtonSize.lg => 24,
          };
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: spinnerSize,
            height: spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
            ),
          ),
          SizedBox(width: spacing),
          _labelOrChild(context),
        ],
      );
    }

    final children = <Widget>[];
    if (leading != null) {
      children.add(leading!);
      children.add(SizedBox(width: spacing));
    }
    children.add(_labelOrChild(context));
    if (trailing != null) {
      children.add(SizedBox(width: spacing));
      children.add(trailing!);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  Widget _labelOrChild(BuildContext context) {
    if (child != null) return child!;
    final TextStyle textStyle = switch (size) {
      AppButtonSize.sm => Theme.of(context).textTheme.labelSmall!,
      AppButtonSize.md => Theme.of(context).textTheme.labelMedium!,
      AppButtonSize.lg => Theme.of(context).textTheme.labelLarge!,
    };
    return Text(label!, style: textStyle);
  }

  ButtonStyle _buildStyle(ThemeData theme) {
    final double effectiveHeight =
        height ??
        switch (size) {
          AppButtonSize.sm => 36,
          AppButtonSize.md => 44,
          AppButtonSize.lg => 52,
        };

    final EdgeInsetsGeometry padding = switch (size) {
      AppButtonSize.sm => const EdgeInsets.symmetric(horizontal: 12),
      AppButtonSize.md => const EdgeInsets.symmetric(horizontal: 16),
      AppButtonSize.lg => const EdgeInsets.symmetric(horizontal: 20),
    };

    final BorderSide outline = BorderSide(color: theme.colorScheme.outline);

    return ButtonStyle(
      padding: WidgetStateProperty.all(padding),
      minimumSize: expand
          ? null
          : WidgetStateProperty.all(Size(0, effectiveHeight)),
      fixedSize: expand
          ? null
          : WidgetStateProperty.resolveWith((states) {
              // Enforce height only; width comes from parent or wrapper.
              return Size.fromHeight(effectiveHeight);
            }),
      side: switch (variant) {
        AppButtonVariant.outline => WidgetStateProperty.all(outline),
        _ => null,
      },
      // Keep shape consistent across variants.
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

enum AppButtonVariant { primary, secondary, outline, text }

enum AppButtonSize { sm, md, lg }

/// Primary elevated-style button.
class PrimaryButton extends AppButton {
  const PrimaryButton({
    super.key,
    super.label,
    super.child,
    super.onPressed,
    super.isLoading,
    super.enabled,
    super.leading,
    super.trailing,
    super.size,
    super.fullWidth,
    super.expand,
    super.height,
    super.loadingIndicatorSize,
  }) : super(variant: AppButtonVariant.primary);
}

/// Secondary tonal-style button.
class SecondaryButton extends AppButton {
  const SecondaryButton({
    super.key,
    super.label,
    super.child,
    super.onPressed,
    super.isLoading,
    super.enabled,
    super.leading,
    super.trailing,
    super.size,
    super.fullWidth,
    super.expand,
    super.height,
    super.loadingIndicatorSize,
  }) : super(variant: AppButtonVariant.secondary);
}

/// Outline style button.
class OutlineButtonApp extends AppButton {
  const OutlineButtonApp({
    super.key,
    super.label,
    super.child,
    super.onPressed,
    super.isLoading,
    super.enabled,
    super.leading,
    super.trailing,
    super.size,
    super.fullWidth,
    super.expand,
    super.height,
    super.loadingIndicatorSize,
  }) : super(variant: AppButtonVariant.outline);
}

/// Text style button.
class TextActionButton extends AppButton {
  const TextActionButton({
    super.key,
    super.label,
    super.child,
    super.onPressed,
    super.isLoading,
    super.enabled,
    super.leading,
    super.trailing,
    super.size,
    super.fullWidth,
    super.expand,
    super.height,
    super.loadingIndicatorSize,
  }) : super(variant: AppButtonVariant.text);
}

/*
USAGE EXAMPLES:

PrimaryButton(
  label: 'Giriş Yap',
  onPressed: () {},
)

SecondaryButton(
  label: 'Kaydol',
  leading: Icon(Icons.person_add),
  onPressed: () {},
)

OutlineButtonApp(
  label: 'Detaylar',
  trailing: Icon(Icons.chevron_right),
  size: AppButtonSize.sm,
  onPressed: () {},
)

TextActionButton(
  label: 'Şifremi Unuttum',
  onPressed: () {},
)

PrimaryButton(
  label: 'Yükleniyor…',
  isLoading: true,
)
*/
