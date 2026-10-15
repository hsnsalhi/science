/// Structure d'écran commune.
library;

import 'package:flutter/material.dart';

import '../core/layout/breakpoints.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_tokens.dart';
import 'app_button.dart';

/// Écran type d'Eurêka.
///
/// Centralise trois choses qu'on oublie sinon un écran sur deux : la marge
/// horizontale adaptée à la largeur, la **borne de largeur du contenu** (sans
/// quoi une tablette de 12 pouces afficherait des lignes de texte de 1 000 px,
/// illisibles), et la zone sûre du bas.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.title,
    this.titleWidget,
    this.actions = const <Widget>[],
    this.onBack,
    this.showBack = false,
    this.bottomBar,
    this.floatingAction,
    this.background,
    this.maxContentWidth = 720,
    this.scrollable = true,
    this.padBody = true,
    super.key,
  });

  /// Largeur maximale du contenu sur grand écran.
  final double maxContentWidth;

  final Widget body;

  /// Titre textuel de l'écran.
  final String? title;

  /// Titre composé, prioritaire sur [title].
  final Widget? titleWidget;

  final List<Widget> actions;

  /// Afficher la flèche de retour.
  final bool showBack;

  /// Action de retour ; par défaut, `Navigator.maybePop`.
  final VoidCallback? onBack;

  /// Barre fixe en bas de l'écran (bouton de validation d'un quiz…).
  final Widget? bottomBar;

  final Widget? floatingAction;

  final Color? background;

  /// Rendre le corps défilant.
  final bool scrollable;

  /// Appliquer la marge horizontale au corps.
  final bool padBody;

  @override
  Widget build(BuildContext context) {
    final double inset = context.screenInset;
    final bool hasHeader =
        title != null || titleWidget != null || showBack || actions.isNotEmpty;

    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxContentWidth),
      child: body,
    );
    if (padBody) {
      content = Padding(
        padding: EdgeInsets.symmetric(horizontal: inset),
        child: content,
      );
    }
    content = Align(alignment: Alignment.topCenter, child: content);
    if (scrollable) {
      content = SingleChildScrollView(
        padding: EdgeInsets.only(
          top: hasHeader ? 0 : AppSpacing.lg,
          bottom: AppSpacing.xxl,
        ),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: hasHeader
          ? AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: inset,
              leading: showBack
                  ? Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Center(
                        child: AppIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Retour',
                          filled: false,
                          onPressed:
                              onBack ?? () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    )
                  : null,
              title:
                  titleWidget ??
                  (title == null
                      ? null
                      : Text(title!, overflow: TextOverflow.ellipsis)),
              actions: <Widget>[
                ...actions,
                SizedBox(width: inset - AppSpacing.sm),
              ],
            )
          : null,
      body: SafeArea(top: !hasHeader, child: content),
      floatingActionButton: floatingAction,
      bottomNavigationBar: bottomBar == null
          ? null
          : _BottomBar(
              inset: inset,
              maxWidth: maxContentWidth,
              child: bottomBar!,
            ),
    );
  }
}

/// Barre basse fixe, posée sur un fond opaque avec un filet de séparation.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.child,
    required this.inset,
    required this.maxWidth,
  });

  final Widget child;
  final double inset;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            inset,
            AppSpacing.md,
            inset,
            AppSpacing.md,
          ),
          // heightFactor: 1 est indispensable. Sans lui, le Center occupe
          // toute la hauteur que le Scaffold lui propose pour la barre basse,
          // et il ne reste plus rien pour le corps de l'écran.
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Titre de section, avec action facultative à droite.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.only(
      top: AppSpacing.xl,
      bottom: AppSpacing.md,
    ),
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.text.headlineSmall),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: context.text.bodySmall?.copyWith(
                      color: context.tokens.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// État vide : un message et, éventuellement, une action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: tokens.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: tokens.inkSubtle),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: context.text.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: context.text.bodyMedium?.copyWith(color: tokens.inkMuted),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
        ],
      ),
    );
  }
}
