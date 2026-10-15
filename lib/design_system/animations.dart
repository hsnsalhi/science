/// Briques d'animation réutilisables.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_spacing.dart';

/// Apparition d'un élément : léger agrandissement et fondu.
///
/// Respecte `context.reduceMotion` : l'enfant est alors affiché tel quel,
/// immédiatement. Aucun contenu n'est jamais invisible à cause d'une
/// animation désactivée — c'est l'erreur classique à ne pas commettre.
class PopIn extends StatefulWidget {
  const PopIn({
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppDurations.base,
    this.from = 0.94,
    super.key,
  });

  final Widget child;

  /// Retard avant le départ, pour enchaîner plusieurs éléments.
  final Duration delay;

  final Duration duration;

  /// Échelle de départ.
  final double from;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    final Animation<double> curved = CurvedAnimation(
      parent: _controller,
      curve: AppCurves.pop,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (BuildContext context, Widget? child) => Opacity(
        opacity: _controller.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: widget.from + (1 - widget.from) * curved.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Apparition par glissement vertical, pour les listes et les cartes.
class SlideFadeIn extends StatelessWidget {
  const SlideFadeIn({
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppDurations.base,
    this.offset = 16,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Décalage vertical de départ, en pixels logiques.
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return _DelayedBuilder(
      delay: delay,
      builder: (BuildContext context, bool started) =>
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: started ? 1 : 0),
            duration: duration,
            curve: AppCurves.enter,
            builder: (BuildContext context, double t, Widget? child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, offset * (1 - t)),
                child: child,
              ),
            ),
            child: child,
          ),
    );
  }
}

/// Enchaîne l'apparition des enfants d'une colonne.
///
/// Évite d'écrire à la main le retard de chaque élément d'un écran.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    required this.children,
    this.step = const Duration(milliseconds: 60),
    this.spacing = 0,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    super.key,
  });

  final List<Widget> children;

  /// Retard ajouté à chaque enfant supplémentaire.
  final Duration step;

  /// Espace inséré entre deux enfants.
  final double spacing;

  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final List<Widget> wrapped = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0 && spacing > 0) wrapped.add(SizedBox(height: spacing));
      wrapped.add(SlideFadeIn(delay: step * i, child: children[i]));
    }
    return Column(crossAxisAlignment: crossAxisAlignment, children: wrapped);
  }
}

/// Secousse horizontale, jouée à chaque changement de [trigger].
///
/// Sert au retour « réponse fausse » : le mouvement est bref et de faible
/// amplitude, pour signaler sans dramatiser.
class Shake extends StatefulWidget {
  const Shake({required this.child, required this.trigger, super.key});

  final Widget child;

  /// Compteur : l'animation rejoue dès que la valeur change.
  final int trigger;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger && widget.trigger > 0) {
      if (!context.reduceMotion) _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        // Sinusoïde amortie : trois oscillations qui s'éteignent.
        final double t = _controller.value;
        final double dx =
            math.sin(t * math.pi * 6) * 9 * (1 - Curves.easeIn.transform(t));
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Nombre qui défile jusqu'à sa nouvelle valeur.
class CountUpText extends StatelessWidget {
  const CountUpText({
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
    super.key,
  });

  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) {
      return Text('$prefix$value$suffix', style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double t, Widget? child) =>
          Text('$prefix${t.round()}$suffix', style: style),
    );
  }
}

/// Pulsation lente et continue, pour attirer l'œil sans agresser.
class GentlePulse extends StatefulWidget {
  const GentlePulse({
    required this.child,
    this.enabled = true,
    this.amplitude = 0.03,
    super.key,
  });

  final Widget child;
  final bool enabled;

  /// Variation d'échelle, en proportion.
  final double amplitude;

  @override
  State<GentlePulse> createState() => _GentlePulseState();
}

class _GentlePulseState extends State<GentlePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(GentlePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Une pulsation infinie ne doit tourner ni quand l'élément est inactif,
  /// ni quand les animations sont réduites.
  void _sync() {
    final bool shouldRun = widget.enabled && !context.reduceMotion;
    if (shouldRun && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldRun && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || context.reduceMotion) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) => Transform.scale(
        scale:
            1 +
            widget.amplitude * Curves.easeInOut.transform(_controller.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Exécute [builder] une première fois avec `started == false`, puis à
/// nouveau avec `true` après [delay].
class _DelayedBuilder extends StatefulWidget {
  const _DelayedBuilder({required this.delay, required this.builder});

  final Duration delay;
  final Widget Function(BuildContext context, bool started) builder;

  @override
  State<_DelayedBuilder> createState() => _DelayedBuilderState();
}

class _DelayedBuilderState extends State<_DelayedBuilder> {
  bool _started = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      // Un cadre d'attente suffit pour que le Tween parte de sa valeur de
      // début : sans cela, l'animation est sautée.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _started = true);
      });
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) setState(() => _started = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _started);
}
