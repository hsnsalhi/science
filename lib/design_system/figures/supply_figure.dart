/// Le trajet du dioxygène et du glucose, de l'entrée jusqu'à la cellule.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'realism.dart';

/// Ce qu'on suit à travers le corps.
enum Cargaison {
  /// Entre par les poumons.
  dioxygene('dioxygène', 'Il entre par les alvéoles.', Color(0xFF4FA3E3)),

  /// Entre par l'intestin, après digestion.
  glucose('glucose', 'Il entre par les villosités intestinales.',
      Color(0xFFE2A33C));

  const Cargaison(this.nom, this.entree, this.couleur);

  final String nom;
  final String entree;

  /// La couleur du jeton qui chemine.
  final Color couleur;
}

/// Une étape du trajet, et où elle se trouve dans le corps.
class Etape {
  const Etape(this.lieu, this.detail, this.point);

  final String lieu;
  final String detail;

  /// Position dans le torse, en coordonnées relatives (0 à 1).
  ///
  /// Les étapes ne sont pas des entrées de liste : chacune est un endroit.
  /// C'est ce qui permet au jeton de se déplacer dans un corps plutôt que
  /// de descendre une colonne de puces.
  final Offset point;
}

/// Le trajet d'une molécule à travers un vrai torse.
///
/// Première version, cette figure était une colonne de pastilles reliées
/// par un trait, avec le nom de l'organe en face de chacune. Autant écrire
/// la liste en toutes lettres : rien n'y ressemblait à un corps, et un
/// élève pouvait la parcourir entière sans jamais savoir où sont les
/// poumons. Un organe est une chose qui existe, et qui a une place.
///
/// Le torse est donc dessiné : les deux poumons avec leur arbre bronchique,
/// le cœur entre eux avec ses quatre cavités et la crosse de l'aorte,
/// l'estomac et l'intestin lové dessous. Le jeton chemine d'un organe à
/// l'autre, et l'organe concerné s'éclaire. Les trois appareils se touchent
/// à l'écran comme ils se touchent dans le corps, ce qui est précisément
/// ce que le chapitre a à faire comprendre.
class SupplyFigure extends StatefulWidget {
  const SupplyFigure({required this.accent, super.key});

  final Color accent;

  /// Le trajet du dioxygène : air, alvéole, sang, cœur, capillaire, cellule.
  static const List<Etape> trajetDioxygene = <Etape>[
    Etape('air inspiré', 'Environ 21 % de dioxygène.', Offset(0.5, 0.05)),
    Etape('alvéole', '300 millions de sacs : la surface d\'échange.',
        Offset(0.29, 0.33)),
    Etape('sang', 'Fixé sur l\'hémoglobine des globules rouges.',
        Offset(0.42, 0.42)),
    Etape('cœur gauche', 'Renvoyé vers tout le corps par l\'aorte.',
        Offset(0.53, 0.44)),
    Etape('capillaire', 'Une paroi d\'une cellule : l\'échange a lieu ici.',
        Offset(0.64, 0.80)),
    Etape('cellule', 'Brûle le glucose et libère l\'énergie.',
        Offset(0.68, 0.90)),
  ];

  /// Le trajet du glucose : aliment, digestion, villosité, sang, cellule.
  static const List<Etape> trajetGlucose = <Etape>[
    Etape('aliment', 'L\'amidon est une chaîne de centaines de glucoses.',
        Offset(0.5, 0.05)),
    Etape('digestion', 'Les enzymes coupent la chaîne en glucoses.',
        Offset(0.40, 0.58)),
    Etape('villosité', 'Des millions de replis : la surface d\'échange.',
        Offset(0.52, 0.70)),
    Etape('sang', 'Transporté dissous, vers le foie puis le corps.',
        Offset(0.62, 0.62)),
    Etape('capillaire', 'Une paroi d\'une cellule : l\'échange a lieu ici.',
        Offset(0.64, 0.80)),
    Etape('cellule', 'Brûlé avec le dioxygène, il libère l\'énergie.',
        Offset(0.68, 0.90)),
  ];

  /// Le trajet correspondant à [cargaison].
  static List<Etape> trajet(Cargaison cargaison) => switch (cargaison) {
    Cargaison.dioxygene => trajetDioxygene,
    Cargaison.glucose => trajetGlucose,
  };

  /// Les deux trajets se rejoignent-ils, et où ?
  ///
  /// Renvoie les lieux communs aux deux, dans l'ordre du trajet. Le
  /// chapitre affirme qu'ils finissent au même endroit ; cette fonction
  /// permet de le vérifier plutôt que de le croire.
  static List<String> lieuxCommuns() {
    final Set<String> glucose =
        trajetGlucose.map((Etape e) => e.lieu).toSet();
    return <String>[
      for (final Etape e in trajetDioxygene)
        if (glucose.contains(e.lieu)) e.lieu,
    ];
  }

  @override
  State<SupplyFigure> createState() => _SupplyFigureState();
}

class _SupplyFigureState extends State<SupplyFigure>
    with SingleTickerProviderStateMixin {
  Cargaison _cargaison = Cargaison.dioxygene;
  int _etape = 0;

  late final AnimationController _glisse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..value = 1;

  List<Etape> get _trajet => SupplyFigure.trajet(_cargaison);

  @override
  void dispose() {
    _glisse.dispose();
    super.dispose();
  }

  void _avancer() {
    setState(() => _etape++);
    _glisse.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Etape courante = _trajet[_etape];
    final bool arrive = _etape == _trajet.length - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          children: Cargaison.values.map((Cargaison c) {
            return ChoiceChip(
              label: Text(c.nom),
              selected: c == _cargaison,
              onSelected: (_) {
                context.tapFeedback();
                setState(() {
                  _cargaison = c;
                  _etape = 0;
                });
                _glisse.value = 1;
              },
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 268,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return AnimatedBuilder(
                  animation: _glisse,
                  builder: (BuildContext context, Widget? _) {
                    return CustomPaint(
                      size: Size(contraintes.maxWidth, 268),
                      painter: _CorpsPainter(
                        trajet: _trajet,
                        etape: _etape,
                        progression: Curves.easeInOut.transform(_glisse.value),
                        cargaison: _cargaison,
                        accent: widget.accent,
                        fond: context.colors.surface,
                        encre: tokens.inkSubtle,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          courante.lieu,
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 17, color: widget.accent),
        ),
        Text(
          courante.detail,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            FilledButton.tonal(
              onPressed: arrive
                  ? null
                  : () {
                      context.tapFeedback();
                      _avancer();
                    },
              child: const Text('étape suivante'),
            ),
            if (_etape > 0)
              OutlinedButton(
                onPressed: () {
                  context.tapFeedback();
                  setState(() => _etape = 0);
                  _glisse.value = 1;
                },
                child: const Text('recommencer'),
              ),
          ],
        ),
        if (arrive)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Les deux trajets finissent ici, dans la même cellule.',
              textAlign: TextAlign.center,
              style: AppTypography.formula(size: 14, color: widget.accent),
            ),
          ),
      ],
    );
  }
}

/// Le torse et ses organes, avec le jeton qui chemine.
class _CorpsPainter extends CustomPainter {
  const _CorpsPainter({
    required this.trajet,
    required this.etape,
    required this.progression,
    required this.cargaison,
    required this.accent,
    required this.fond,
    required this.encre,
  });

  final List<Etape> trajet;
  final int etape;
  final double progression;
  final Cargaison cargaison;
  final Color accent;
  final Color fond;
  final Color encre;

  static const Color _peau = Color(0xFFE8C4A8);
  static const Color _poumon = Color(0xFFD98C8C);
  static const Color _coeur = Color(0xFFC0453F);
  static const Color _digestif = Color(0xFFD9A05B);

  /// L'organe mis en avant à cette étape.
  String get _lieuCourant => trajet[etape].lieu;

  bool _actif(List<String> lieux) => lieux.contains(_lieuCourant);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fond);
    _torse(canvas, size);
    _voiesAeriennes(canvas, size);
    _poumons(canvas, size);
    _appareilDigestif(canvas, size);
    _circulation(canvas, size);
    _organeCoeur(canvas, size);
    _celluleCible(canvas, size);
    _jeton(canvas, size);
  }

  Offset _p(Size size, Offset relatif) =>
      Offset(relatif.dx * size.width, relatif.dy * size.height);

  /// La silhouette du torse, cou et épaules compris.
  void _torse(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final Path corps = Path()
      // Le cou.
      ..moveTo(cx - 17, size.height * 0.02)
      ..lineTo(cx - 15, size.height * 0.10)
      // L'épaule gauche, puis le flanc qui se creuse à la taille.
      ..cubicTo(
        cx - 70, size.height * 0.13,
        cx - 92, size.height * 0.22,
        cx - 88, size.height * 0.40,
      )
      ..cubicTo(
        cx - 85, size.height * 0.56,
        cx - 78, size.height * 0.66,
        cx - 80, size.height * 0.84,
      )
      ..lineTo(cx - 76, size.height * 0.99)
      ..lineTo(cx + 76, size.height * 0.99)
      ..lineTo(cx + 80, size.height * 0.84)
      ..cubicTo(
        cx + 78, size.height * 0.66,
        cx + 85, size.height * 0.56,
        cx + 88, size.height * 0.40,
      )
      ..cubicTo(
        cx + 92, size.height * 0.22,
        cx + 70, size.height * 0.13,
        cx + 15, size.height * 0.10,
      )
      ..lineTo(cx + 17, size.height * 0.02)
      ..close();

    canvas.drawPath(
      corps,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.1,
          colors: <Color>[
            Color.lerp(_peau, Colors.white, 0.3)!,
            _peau,
            Color.lerp(_peau, Colors.black, 0.16)!,
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      corps,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Color.lerp(_peau, Colors.black, 0.35)!,
    );

    // La cage thoracique, devinée sous la peau : quelques côtes suffisent
    // à dire qu'il y a un volume protégé là-dessous.
    for (int i = 0; i < 5; i++) {
      final double y = size.height * (0.20 + i * 0.055);
      final double largeur = 74 - i * 2.0;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, y),
          width: largeur * 2,
          height: 34,
        ),
        math.pi * 1.08,
        math.pi * 0.84,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.22),
      );
    }
  }

  /// Trachée et bronches, de la bouche aux poumons.
  void _voiesAeriennes(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final bool actif = _actif(<String>['air inspiré', 'alvéole']);
    final Paint tuyau = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = (actif ? accent : const Color(0xFFBFA79A))
          .withValues(alpha: actif ? 0.9 : 0.75);

    // La trachée, avec ses anneaux cartilagineux.
    canvas.drawLine(
      Offset(cx, size.height * 0.04),
      Offset(cx, size.height * 0.27),
      tuyau,
    );
    for (double y = size.height * 0.07; y < size.height * 0.26; y += 7) {
      canvas.drawLine(
        Offset(cx - 3.5, y),
        Offset(cx + 3.5, y),
        Paint()
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.4),
      );
    }

    // Les deux bronches souches, puis deux divisions de plus. L'arbre
    // bronchique se divise une vingtaine de fois dans la réalité ; trois
    // suffisent à dire « arbre » sans faire bouillie.
    void branche(Offset depuis, double angle, double longueur, int reste) {
      if (reste == 0) return;
      final Offset vers = depuis +
          Offset(math.cos(angle) * longueur, math.sin(angle) * longueur);
      canvas.drawLine(
        depuis,
        vers,
        Paint()
          ..strokeWidth = reste * 1.7
          ..strokeCap = StrokeCap.round
          ..color = tuyau.color,
      );
      branche(vers, angle - 0.55, longueur * 0.62, reste - 1);
      branche(vers, angle + 0.45, longueur * 0.62, reste - 1);
    }

    final Offset carene = Offset(cx, size.height * 0.27);
    branche(carene, math.pi - 0.75, 26, 3);
    branche(carene, 0.75, 26, 3);
  }

  /// Les deux poumons, lobés et irréguliers.
  void _poumons(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final bool actif = _actif(<String>['alvéole']);
    for (final int cote in <int>[-1, 1]) {
      final Rect cadre = Rect.fromCenter(
        center: Offset(cx + cote * 44, size.height * 0.34),
        width: 62,
        height: 96,
      );
      // Un contour organique : un poumon n'a pas de bord régulier, et un
      // ovale lisse serait la marque du schéma.
      final Path forme = Realisme.paroiOrganique(
        cadre,
        graine: cote > 0 ? 21 : 22,
        sommets: 13,
        irregularite: 0.13,
      );
      canvas.drawPath(forme, Realisme.chair(cadre, _poumon));
      if (actif) {
        canvas.drawPath(
          forme,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = accent,
        );
      }
      // Les scissures qui séparent les lobes : trois à droite, deux à
      // gauche, parce que le cœur prend la place du troisième.
      canvas.save();
      canvas.clipPath(forme);
      for (int i = 0; i < (cote < 0 ? 2 : 1); i++) {
        canvas.drawLine(
          Offset(cadre.left, cadre.top + cadre.height * (0.34 + i * 0.3)),
          Offset(cadre.right, cadre.top + cadre.height * (0.46 + i * 0.3)),
          Paint()
            ..strokeWidth = 1.4
            ..color = Colors.black.withValues(alpha: 0.18),
        );
      }
      // Le grain alvéolaire : des centaines de petites poches, pas une
      // masse pleine. C'est l'argument du chapitre sur la surface.
      final math.Random alea = math.Random(cote > 0 ? 31 : 32);
      for (int i = 0; i < 90; i++) {
        canvas.drawCircle(
          Offset(
            cadre.left + alea.nextDouble() * cadre.width,
            cadre.top + alea.nextDouble() * cadre.height,
          ),
          1.1 + alea.nextDouble() * 1.5,
          Paint()
            ..color = Colors.white.withValues(
              alpha: 0.10 + alea.nextDouble() * 0.16,
            ),
        );
      }
      canvas.restore();
    }
  }

  /// Estomac et intestin grêle.
  void _appareilDigestif(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final bool estomacActif = _actif(<String>['aliment', 'digestion']);
    final bool intestinActif = _actif(<String>['villosité']);

    // L'œsophage, qui descend derrière le cœur jusqu'à l'estomac.
    canvas.drawPath(
      Path()
        ..moveTo(cx + 3, size.height * 0.10)
        ..cubicTo(
          cx + 2, size.height * 0.32,
          cx - 14, size.height * 0.44,
          cx - 20, size.height * 0.53,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = (estomacActif ? accent : const Color(0xFFC9A98C))
            .withValues(alpha: 0.85),
    );

    // L'estomac : une poche en J, pas un haricot symétrique.
    final Path estomac = Path()
      ..moveTo(cx - 20, size.height * 0.53)
      ..cubicTo(
        cx - 48, size.height * 0.55,
        cx - 54, size.height * 0.66,
        cx - 30, size.height * 0.69,
      )
      ..cubicTo(
        cx - 12, size.height * 0.71,
        cx - 4, size.height * 0.66,
        cx - 2, size.height * 0.61,
      )
      ..cubicTo(
        cx - 6, size.height * 0.64,
        cx - 18, size.height * 0.66,
        cx - 24, size.height * 0.63,
      )
      ..cubicTo(
        cx - 36, size.height * 0.60,
        cx - 30, size.height * 0.55,
        cx - 20, size.height * 0.53,
      )
      ..close();
    final Rect cadreEstomac = estomac.getBounds();
    canvas.drawPath(estomac, Realisme.chair(cadreEstomac, _digestif));
    if (estomacActif) {
      canvas.drawPath(
        estomac,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = accent,
      );
    }

    // L'intestin grêle : six mètres lovés, qu'on figure par un serpentin
    // continu. Des boucles régulières seraient fausses, mais un trait
    // unique dit bien « un seul tuyau très long ».
    final Path intestin = Path()
      ..moveTo(cx - 30, size.height * 0.69);
    final math.Random alea = math.Random(17);
    double x = cx - 30;
    double y = size.height * 0.70;
    int sens = 1;
    for (int rang = 0; rang < 5; rang++) {
      final double cible = sens > 0 ? cx + 44 : cx - 44;
      final double prochainY = y + 13 + alea.nextDouble() * 3;
      intestin.cubicTo(
        x + sens * 30, y - 9,
        cible - sens * 12, y + 4,
        cible, prochainY,
      );
      x = cible;
      y = prochainY;
      sens = -sens;
    }
    canvas.drawPath(
      intestin,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Color.lerp(_digestif, Colors.black, 0.22)!,
    );
    canvas.drawPath(
      intestin,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = intestinActif
            ? accent
            : Color.lerp(_digestif, Colors.white, 0.18)!,
    );
  }

  /// Les gros vaisseaux : rouges au départ du cœur, bleus au retour.
  void _circulation(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final bool actif = _actif(<String>['sang', 'capillaire']);
    final double epaisseur = actif ? 4.4 : 3.2;

    // L'aorte : elle sort du cœur, décrit une crosse, puis descend. C'est
    // la forme réelle, et elle explique pourquoi le sang part vers le haut
    // avant d'aller partout.
    canvas.drawPath(
      Path()
        ..moveTo(cx + 4, size.height * 0.47)
        ..cubicTo(
          cx + 6, size.height * 0.38,
          cx + 2, size.height * 0.30,
          cx - 10, size.height * 0.30,
        )
        ..cubicTo(
          cx - 20, size.height * 0.31,
          cx - 16, size.height * 0.42,
          cx - 10, size.height * 0.52,
        )
        ..cubicTo(
          cx - 2, size.height * 0.68,
          cx + 30, size.height * 0.74,
          cx + 62, size.height * 0.80,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = epaisseur
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFCB3C3C).withValues(alpha: 0.9),
    );

    // La veine cave : le retour, en bleu, du bas vers le cœur droit.
    canvas.drawPath(
      Path()
        ..moveTo(cx + 66, size.height * 0.84)
        ..cubicTo(
          cx + 34, size.height * 0.78,
          cx + 14, size.height * 0.62,
          cx + 12, size.height * 0.50,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = epaisseur
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3B6FB5).withValues(alpha: 0.9),
    );

    // Les vaisseaux pulmonaires : artère bleue vers les poumons, veine
    // rouge au retour. C'est l'exception que le chapitre martèle — une
    // artère n'est pas définie par son sang.
    for (final int cote in <int>[-1, 1]) {
      canvas.drawLine(
        Offset(cx + cote * 6, size.height * 0.42),
        Offset(cx + cote * 30, size.height * 0.36),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = (cote < 0
                  ? const Color(0xFF3B6FB5)
                  : const Color(0xFFCB3C3C))
              .withValues(alpha: 0.85),
      );
    }
  }

  /// Le cœur, ses quatre cavités et son inclinaison.
  void _organeCoeur(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final bool actif = _actif(<String>['cœur gauche']);
    final Rect cadre = Rect.fromCenter(
      center: Offset(cx + 2, size.height * 0.44),
      width: 42,
      height: 62,
    );

    canvas.save();
    // Le cœur penche vers la gauche et pointe vers le bas : c'est sa vraie
    // position, et elle n'a rien du symbole.
    canvas.translate(cadre.center.dx, cadre.center.dy);
    canvas.rotate(0.22);
    canvas.translate(-cadre.center.dx, -cadre.center.dy);

    // Un cœur anatomique n'a pas d'échancrure au sommet : c'est justement
    // elle qui fait le symbole des cartes à jouer. Le vrai organe est un
    // cône émoussé, large à la base où arrivent les oreillettes, effilé
    // vers une pointe — l'apex — dirigée en bas et à gauche.
    final Path muscle = Path()
      // La base, en haut : large, légèrement bombée, sans creux central.
      ..moveTo(cadre.left + 3, cadre.top + 14)
      ..cubicTo(
        cadre.left + 1, cadre.top + 2,
        cadre.center.dx - 6, cadre.top - 1,
        cadre.center.dx + 2, cadre.top + 2,
      )
      ..cubicTo(
        cadre.center.dx + 12, cadre.top + 4,
        cadre.right - 1, cadre.top + 3,
        cadre.right - 2, cadre.top + 17,
      )
      // Le bord droit : le ventricule droit, bombé.
      ..cubicTo(
        cadre.right + 2, cadre.top + 32,
        cadre.right - 8, cadre.bottom - 14,
        cadre.center.dx + 2, cadre.bottom - 3,
      )
      // L'apex : la pointe du ventricule gauche, dirigée en bas à gauche.
      // C'est elle qu'on sent battre contre les côtes, et sans elle
      // l'organe n'est qu'une masse.
      ..cubicTo(
        cadre.center.dx - 3, cadre.bottom + 3,
        cadre.center.dx - 9, cadre.bottom + 2,
        cadre.center.dx - 13, cadre.bottom - 9,
      )
      // Le bord gauche : le ventricule gauche, plus épais et plus droit.
      ..cubicTo(
        cadre.left - 2, cadre.bottom - 22,
        cadre.left - 1, cadre.top + 28,
        cadre.left + 3, cadre.top + 14,
      )
      ..close();

    canvas.drawPath(muscle, Realisme.chair(cadre, _coeur));
    canvas.drawPath(
      muscle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = actif ? 2.6 : 1.2
        ..color = actif
            ? accent
            : Color.lerp(_coeur, Colors.black, 0.4)!,
    );

    // Le sillon qui sépare les deux moitiés, et les artères coronaires.
    canvas.save();
    canvas.clipPath(muscle);
    canvas.drawLine(
      Offset(cadre.center.dx + 1, cadre.top + 10),
      Offset(cadre.center.dx - 3, cadre.bottom),
      Paint()
        ..strokeWidth = 2
        ..color = Colors.black.withValues(alpha: 0.22),
    );
    canvas.drawPath(
      Path()
        ..moveTo(cadre.left + 6, cadre.top + 22)
        ..quadraticBezierTo(
          cadre.center.dx, cadre.top + 28,
          cadre.right - 6, cadre.top + 24,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.restore();
    canvas.restore();
  }

  /// La cellule qui attend sa livraison, et son capillaire.
  void _celluleCible(Canvas canvas, Size size) {
    final Offset centre = _p(size, const Offset(0.68, 0.90));
    final bool actif = _actif(<String>['cellule', 'capillaire']);
    final Rect cadre = Rect.fromCenter(center: centre, width: 40, height: 32);

    final Path membrane = Realisme.paroiOrganique(
      cadre,
      graine: 41,
      sommets: 11,
      irregularite: 0.12,
    );
    canvas.drawPath(membrane, Realisme.chair(cadre, const Color(0xFF8FBF8C)));
    canvas.drawPath(
      membrane,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = actif ? 2.4 : 1.2
        ..color = actif ? accent : const Color(0xFF4F7A4C),
    );
    // Le noyau.
    canvas.drawCircle(
      centre.translate(-3, 1),
      7,
      Paint()..color = const Color(0xFF3F6B4D).withValues(alpha: 0.75),
    );
  }

  /// Le jeton qui chemine, et la trace de son parcours.
  void _jeton(Canvas canvas, Size size) {
    // La trace déjà parcourue : elle montre que les étapes forment un
    // trajet continu, et non une suite d'endroits sans rapport.
    final Path trace = Path();
    for (int i = 0; i <= etape; i++) {
      final Offset point = _p(size, trajet[i].point);
      if (i == 0) {
        trace.moveTo(point.dx, point.dy);
      } else {
        trace.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      trace,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = cargaison.couleur.withValues(alpha: 0.45),
    );

    // Le jeton glisse de l'étape précédente vers la courante, plutôt que
    // de sauter : c'est le déplacement qui fait comprendre qu'il s'agit
    // d'un transport.
    final Offset vers = _p(size, trajet[etape].point);
    final Offset depuis =
        etape == 0 ? vers : _p(size, trajet[etape - 1].point);
    final Offset position = Offset.lerp(depuis, vers, progression)!;

    canvas.drawCircle(
      position,
      11,
      Paint()
        ..color = cargaison.couleur.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      position,
      6.5,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: <Color>[
            Color.lerp(cargaison.couleur, Colors.white, 0.6)!,
            cargaison.couleur,
          ],
        ).createShader(
          Rect.fromCircle(center: position, radius: 6.5),
        ),
    );
  }

  @override
  bool shouldRepaint(_CorpsPainter old) =>
      old.etape != etape ||
      old.progression != progression ||
      old.cargaison != cargaison ||
      old.accent != accent;
}
