import 'dart:math' as math;

import 'package:flutter/material.dart';

enum SiqiGlyph {
  brand,
  chat,
  lab,
  settings,
  cloud,
  key,
  chip,
  agent,
  harness,
  mcp,
  market,
  terminal,
  review,
  github,
  image,
  pdf,
  audio,
  code,
  folder,
  download,
  pause,
  play,
  stop,
  search,
  add,
  send,
  history,
  export,
  import,
  database,
  webhook,
  shield,
  palette,
  globe,
  memory,
  storage,
  tokens,
  cost,
  link,
  check,
  warning,
  close,
  chevronRight,
  sparkles,
  user,
  theme,
  info,
  copy,
  refresh,
  queue,
  workspace,
  tools,
}

class SiqiIcon extends StatelessWidget {
  const SiqiIcon(
    this.glyph, {
    this.size = 24,
    this.color,
    this.strokeWidth = 1.8,
    this.semanticLabel,
    super.key,
  });
  final SiqiGlyph glyph;
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    final icon = CustomPaint(
      size: Size.square(size),
      painter: _SiqiIconPainter(glyph, resolved, strokeWidth),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: icon)
        : Semantics(label: semanticLabel, image: true, child: icon);
  }
}

class SiqiBrandMark extends StatelessWidget {
  const SiqiBrandMark({
    this.size = 44,
    this.foreground,
    this.background,
    super.key,
  });
  final double size;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(size * .24),
        border: Border.all(color: colors.outlineVariant),
      ),
      alignment: Alignment.center,
      child: SiqiIcon(
        SiqiGlyph.brand,
        size: size * .66,
        color: foreground ?? colors.primary,
        strokeWidth: 2.15,
      ),
    );
  }
}

class _SiqiIconPainter extends CustomPainter {
  const _SiqiIconPainter(this.glyph, this.color, this.strokeWidth);
  final SiqiGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final f = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    switch (glyph) {
      case SiqiGlyph.brand:
        _brand(canvas, p);
      case SiqiGlyph.chat:
        _chat(canvas, p);
      case SiqiGlyph.lab:
        _lab(canvas, p);
      case SiqiGlyph.settings:
        _settings(canvas, p);
      case SiqiGlyph.cloud:
        _cloud(canvas, p);
      case SiqiGlyph.key:
        _key(canvas, p);
      case SiqiGlyph.chip:
        _chip(canvas, p);
      case SiqiGlyph.agent:
        _agent(canvas, p, f);
      case SiqiGlyph.harness:
        _harness(canvas, p);
      case SiqiGlyph.mcp:
        _mcp(canvas, p, f);
      case SiqiGlyph.market:
        _market(canvas, p);
      case SiqiGlyph.terminal:
        _terminal(canvas, p);
      case SiqiGlyph.review:
        _review(canvas, p);
      case SiqiGlyph.github:
        _github(canvas, p);
      case SiqiGlyph.image:
        _image(canvas, p, f);
      case SiqiGlyph.pdf:
        _document(canvas, p, 'P');
      case SiqiGlyph.audio:
        _audio(canvas, p, f);
      case SiqiGlyph.code:
        _code(canvas, p);
      case SiqiGlyph.folder:
        _folder(canvas, p);
      case SiqiGlyph.download:
        _arrowTray(canvas, p, false);
      case SiqiGlyph.export:
        _arrowTray(canvas, p, true);
      case SiqiGlyph.import:
        _import(canvas, p);
      case SiqiGlyph.pause:
        _lines(canvas, p, const [
          Offset(9, 7),
          Offset(9, 17),
          Offset(15, 7),
          Offset(15, 17),
        ]);
      case SiqiGlyph.play:
        canvas.drawPath(
          Path()
            ..moveTo(9, 7)
            ..lineTo(17, 12)
            ..lineTo(9, 17)
            ..close(),
          p,
        );
      case SiqiGlyph.stop:
        _roundRect(canvas, p, const Rect.fromLTWH(7, 7, 10, 10), 2.2);
      case SiqiGlyph.search:
        canvas.drawCircle(const Offset(10.5, 10.5), 5.5, p);
        _line(canvas, p, 14.7, 14.7, 19, 19);
      case SiqiGlyph.add:
        _lines(canvas, p, const [
          Offset(12, 5),
          Offset(12, 19),
          Offset(5, 12),
          Offset(19, 12),
        ]);
      case SiqiGlyph.send:
        _send(canvas, p);
      case SiqiGlyph.history:
        _history(canvas, p);
      case SiqiGlyph.database:
        _database(canvas, p);
      case SiqiGlyph.webhook:
        _webhook(canvas, p);
      case SiqiGlyph.shield:
        _shield(canvas, p);
      case SiqiGlyph.palette:
        _palette(canvas, p, f);
      case SiqiGlyph.globe:
        _globe(canvas, p);
      case SiqiGlyph.memory:
        _memory(canvas, p);
      case SiqiGlyph.storage:
        _storage(canvas, p, f);
      case SiqiGlyph.tokens:
        _tokens(canvas, p);
      case SiqiGlyph.cost:
        _cost(canvas, p);
      case SiqiGlyph.link:
        _link(canvas, p);
      case SiqiGlyph.check:
        canvas.drawPath(
          Path()
            ..moveTo(5, 12.5)
            ..lineTo(10, 17)
            ..lineTo(19, 7),
          p,
        );
      case SiqiGlyph.warning:
        _warning(canvas, p, f);
      case SiqiGlyph.close:
        _lines(canvas, p, const [
          Offset(6, 6),
          Offset(18, 18),
          Offset(18, 6),
          Offset(6, 18),
        ]);
      case SiqiGlyph.chevronRight:
        canvas.drawPath(
          Path()
            ..moveTo(9, 5)
            ..lineTo(16, 12)
            ..lineTo(9, 19),
          p,
        );
      case SiqiGlyph.sparkles:
        _sparkles(canvas, p);
      case SiqiGlyph.user:
        _user(canvas, p);
      case SiqiGlyph.theme:
        _theme(canvas, p);
      case SiqiGlyph.info:
        canvas.drawCircle(const Offset(12, 12), 8, p);
        canvas.drawCircle(const Offset(12, 8), .8, f);
        _line(canvas, p, 12, 11, 12, 16);
      case SiqiGlyph.copy:
        _copy(canvas, p);
      case SiqiGlyph.refresh:
        _refresh(canvas, p);
      case SiqiGlyph.queue:
        _queue(canvas, p, f);
      case SiqiGlyph.workspace:
        _workspace(canvas, p);
      case SiqiGlyph.tools:
        _tools(canvas, p);
    }
    canvas.restore();
  }

  void _line(Canvas c, Paint p, double x1, double y1, double x2, double y2) =>
      c.drawLine(Offset(x1, y1), Offset(x2, y2), p);
  void _lines(Canvas c, Paint p, List<Offset> values) {
    for (var i = 0; i < values.length; i += 2) {
      c.drawLine(values[i], values[i + 1], p);
    }
  }

  void _roundRect(Canvas c, Paint p, Rect rect, double radius) =>
      c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), p);

  void _brand(Canvas c, Paint p) {
    _roundRect(c, p, const Rect.fromLTWH(4, 4, 16, 16), 4.5);
    _lines(c, p, const [
      Offset(8, 8.2),
      Offset(16, 8.2),
      Offset(8, 12),
      Offset(13.5, 12),
    ]);
    c.drawPath(
      Path()
        ..moveTo(11, 16.3)
        ..lineTo(16.5, 12)
        ..lineTo(16.5, 16.3),
      p,
    );
  }

  void _chat(Canvas c, Paint p) {
    _roundRect(c, p, const Rect.fromLTWH(3, 4, 18, 14), 5);
    c.drawPath(
      Path()
        ..moveTo(8, 18)
        ..lineTo(6, 21)
        ..lineTo(12, 18),
      p,
    );
    _lines(c, p, const [
      Offset(7.5, 9),
      Offset(16.5, 9),
      Offset(7.5, 13),
      Offset(13.5, 13),
    ]);
  }

  void _lab(Canvas c, Paint p) {
    _lines(c, p, const [
      Offset(9, 3),
      Offset(15, 3),
      Offset(10, 3),
      Offset(10, 9),
      Offset(14, 3),
      Offset(14, 9),
    ]);
    c.drawPath(
      Path()
        ..moveTo(10, 8)
        ..lineTo(5, 17)
        ..quadraticBezierTo(4, 20, 8, 21)
        ..lineTo(16, 21)
        ..quadraticBezierTo(20, 20, 19, 17)
        ..lineTo(14, 8),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(7.2, 16)
        ..quadraticBezierTo(10, 14, 12, 16)
        ..quadraticBezierTo(14, 18, 17, 16),
      p,
    );
  }

  void _settings(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 12), 3.2, p);
    c.drawCircle(const Offset(12, 12), 8, p);
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      path.moveTo(12 + math.cos(a) * 7, 12 + math.sin(a) * 7);
      path.lineTo(12 + math.cos(a) * 9, 12 + math.sin(a) * 9);
    }
    c.drawPath(path, p);
  }

  void _cloud(Canvas c, Paint p) => c.drawPath(
    Path()
      ..moveTo(6.5, 18)
      ..cubicTo(1.5, 18, 1.5, 11, 6.5, 10.5)
      ..cubicTo(7.5, 4, 16.5, 4, 18, 10)
      ..cubicTo(23, 10.5, 22.5, 18, 17.5, 18)
      ..close(),
    p,
  );
  void _key(Canvas c, Paint p) {
    c.drawCircle(const Offset(8, 12), 4, p);
    _lines(c, p, const [
      Offset(12, 12),
      Offset(21, 12),
      Offset(17, 12),
      Offset(17, 15),
      Offset(20, 12),
      Offset(20, 14),
    ]);
  }

  void _chip(Canvas c, Paint p) {
    _roundRect(c, p, const Rect.fromLTWH(6, 6, 12, 12), 2.5);
    c.drawCircle(const Offset(12, 12), 3, p);
    for (final v in const [8.0, 12.0, 16.0]) {
      _lines(c, p, [
        Offset(v, 4),
        Offset(v, 6),
        Offset(v, 18),
        Offset(v, 20),
        Offset(4, v),
        Offset(6, v),
        Offset(18, v),
        Offset(20, v),
      ]);
    }
  }

  void _agent(Canvas c, Paint p, Paint f) {
    _roundRect(c, p, const Rect.fromLTWH(4, 6, 16, 13), 4);
    _line(c, p, 12, 3, 12, 6);
    c.drawCircle(const Offset(12, 3), 1, f);
    c.drawCircle(const Offset(9, 12), 1, f);
    c.drawCircle(const Offset(15, 12), 1, f);
    c.drawPath(
      Path()
        ..moveTo(8.5, 15)
        ..quadraticBezierTo(12, 17.5, 15.5, 15),
      p,
    );
  }

  void _harness(Canvas c, Paint p) {
    _roundRect(c, p, const Rect.fromLTWH(4, 3, 16, 18), 3);
    c.drawPath(
      Path()
        ..moveTo(8, 8)
        ..lineTo(10, 10)
        ..lineTo(14, 6),
      p,
    );
    _lines(c, p, const [
      Offset(8, 14),
      Offset(16, 14),
      Offset(8, 17),
      Offset(14, 17),
    ]);
  }

  void _mcp(Canvas c, Paint p, Paint f) {
    for (final point in const [
      Offset(5, 12),
      Offset(12, 5),
      Offset(19, 12),
      Offset(12, 19),
    ]) {
      c.drawCircle(point, 2.2, p);
      c.drawCircle(point, .7, f);
    }
    _lines(c, p, const [
      Offset(7, 11),
      Offset(10.5, 6.5),
      Offset(13.5, 6.5),
      Offset(17, 11),
      Offset(17, 13),
      Offset(13.5, 17.5),
      Offset(10.5, 17.5),
      Offset(7, 13),
    ]);
  }

  void _market(Canvas c, Paint p) {
    _roundRect(c, p, const Rect.fromLTWH(4, 7, 16, 13), 3);
    c.drawPath(
      Path()
        ..moveTo(7, 7)
        ..quadraticBezierTo(7, 3, 12, 3)
        ..quadraticBezierTo(17, 3, 17, 7),
      p,
    );
    _lines(c, p, const [
      Offset(8, 12),
      Offset(16, 12),
      Offset(12, 9),
      Offset(12, 16),
    ]);
    c.drawPath(
      Path()
        ..moveTo(9.5, 14)
        ..lineTo(12, 16.5)
        ..lineTo(14.5, 14),
      p,
    );
  }

  void _terminal(Canvas c, Paint p) {
    _roundRect(c, p, const Rect.fromLTWH(3, 4, 18, 16), 3);
    c.drawPath(
      Path()
        ..moveTo(7, 9)
        ..lineTo(10, 12)
        ..lineTo(7, 15),
      p,
    );
    _line(c, p, 13, 15, 17, 15);
  }

  void _review(Canvas c, Paint p) {
    _documentShape(c, p);
    c.drawCircle(const Offset(15.5, 15.5), 3.5, p);
    _lines(c, p, const [
      Offset(18, 18),
      Offset(21, 21),
      Offset(7, 8),
      Offset(14, 8),
      Offset(7, 12),
      Offset(11, 12),
    ]);
  }

  void _github(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 11), 8, p);
    c.drawPath(
      Path()
        ..moveTo(8, 19)
        ..cubicTo(8, 16, 9, 15, 10, 15)
        ..cubicTo(6, 15, 6, 11, 7, 9)
        ..cubicTo(6.5, 7, 7, 5.5, 7.5, 5)
        ..cubicTo(9.5, 5, 10.5, 6, 12, 6)
        ..cubicTo(13.5, 6, 14.5, 5, 16.5, 5)
        ..cubicTo(17, 5.5, 17.5, 7, 17, 9)
        ..cubicTo(18, 11, 18, 15, 14, 15)
        ..cubicTo(15, 16, 16, 17, 16, 19),
      p,
    );
  }

  void _image(Canvas c, Paint p, Paint f) {
    _roundRect(c, p, const Rect.fromLTWH(3, 4, 18, 16), 3);
    c.drawCircle(const Offset(9, 9), 1.4, f);
    c.drawPath(
      Path()
        ..moveTo(5, 17)
        ..lineTo(10, 12)
        ..lineTo(13, 15)
        ..lineTo(16, 11)
        ..lineTo(20, 16),
      p,
    );
  }

  void _document(Canvas c, Paint p, String letter) {
    _documentShape(c, p);
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, const Offset(8.2, 10));
  }

  void _documentShape(Canvas c, Paint p) => c.drawPath(
    Path()
      ..moveTo(6, 3)
      ..lineTo(14, 3)
      ..lineTo(19, 8)
      ..lineTo(19, 21)
      ..lineTo(6, 21)
      ..close()
      ..moveTo(14, 3)
      ..lineTo(14, 8)
      ..lineTo(19, 8),
    p,
  );
  void _audio(Canvas c, Paint p, Paint f) {
    c.drawPath(
      Path()
        ..moveTo(9, 17)
        ..lineTo(9, 6)
        ..lineTo(18, 4)
        ..lineTo(18, 15),
      p,
    );
    c.drawCircle(const Offset(6.5, 17), 2.5, p);
    c.drawCircle(const Offset(15.5, 15), 2.5, p);
    c.drawCircle(const Offset(6.5, 17), .6, f);
    c.drawCircle(const Offset(15.5, 15), .6, f);
  }

  void _code(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(9, 6)
        ..lineTo(3, 12)
        ..lineTo(9, 18),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(15, 6)
        ..lineTo(21, 12)
        ..lineTo(15, 18),
      p,
    );
    _line(c, p, 14, 4, 10, 20);
  }

  void _folder(Canvas c, Paint p) => c.drawPath(
    Path()
      ..moveTo(3, 7)
      ..quadraticBezierTo(3, 5, 5, 5)
      ..lineTo(10, 5)
      ..lineTo(12, 8)
      ..lineTo(19, 8)
      ..quadraticBezierTo(21, 8, 21, 10)
      ..lineTo(21, 18)
      ..quadraticBezierTo(21, 20, 19, 20)
      ..lineTo(5, 20)
      ..quadraticBezierTo(3, 20, 3, 18)
      ..close(),
    p,
  );
  void _arrowTray(Canvas c, Paint p, bool up) {
    final start = up ? 16.0 : 6.0;
    final end = up ? 7.0 : 15.0;
    _line(c, p, 12, start, 12, end);
    c.drawPath(
      up
          ? (Path()
              ..moveTo(8, 10)
              ..lineTo(12, 6)
              ..lineTo(16, 10))
          : (Path()
              ..moveTo(8, 12)
              ..lineTo(12, 16)
              ..lineTo(16, 12)),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(5, 17)
        ..lineTo(5, 20)
        ..lineTo(19, 20)
        ..lineTo(19, 17),
      p,
    );
  }

  void _import(Canvas c, Paint p) {
    _line(c, p, 12, 5, 12, 14);
    c.drawPath(
      Path()
        ..moveTo(8, 11)
        ..lineTo(12, 15)
        ..lineTo(16, 11),
      p,
    );
    _roundRect(c, p, const Rect.fromLTWH(4, 4, 16, 16), 3);
  }

  void _send(Canvas c, Paint p) => c.drawPath(
    Path()
      ..moveTo(3, 11)
      ..lineTo(21, 3)
      ..lineTo(14, 21)
      ..lineTo(11, 13)
      ..close()
      ..moveTo(11, 13)
      ..lineTo(21, 3),
    p,
  );
  void _history(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(5, 8)
        ..lineTo(5, 4)
        ..lineTo(1, 4)
        ..moveTo(5, 5)
        ..cubicTo(8, 2, 14, 2, 18, 6)
        ..cubicTo(23, 11, 20, 20, 13, 21)
        ..cubicTo(8, 22, 4, 18, 3, 14),
      p,
    );
    _lines(c, p, const [
      Offset(12, 7),
      Offset(12, 13),
      Offset(12, 13),
      Offset(16, 15),
    ]);
  }

  void _database(Canvas c, Paint p) {
    c.drawOval(const Rect.fromLTWH(4, 3, 16, 6), p);
    c.drawPath(
      Path()
        ..moveTo(4, 6)
        ..lineTo(4, 18)
        ..cubicTo(4, 22, 20, 22, 20, 18)
        ..lineTo(20, 6),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(4, 12)
        ..cubicTo(4, 16, 20, 16, 20, 12),
      p,
    );
  }

  void _webhook(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(8, 14)
        ..cubicTo(3, 13, 3, 6, 8, 5)
        ..cubicTo(11, 4, 13, 7, 12, 9),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(16, 10)
        ..cubicTo(21, 11, 21, 18, 16, 19)
        ..cubicTo(13, 20, 11, 17, 12, 15),
      p,
    );
    _line(c, p, 8, 14, 16, 10);
    c.drawCircle(const Offset(8, 14), 1.4, p);
    c.drawCircle(const Offset(16, 10), 1.4, p);
  }

  void _shield(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(12, 3)
        ..cubicTo(15, 5, 18, 5, 20, 6)
        ..lineTo(20, 12)
        ..cubicTo(20, 17, 16, 20, 12, 22)
        ..cubicTo(8, 20, 4, 17, 4, 12)
        ..lineTo(4, 6)
        ..cubicTo(6, 5, 9, 5, 12, 3)
        ..close(),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(8, 12)
        ..lineTo(11, 15)
        ..lineTo(16, 9),
      p,
    );
  }

  void _palette(Canvas c, Paint p, Paint f) {
    c.drawPath(
      Path()
        ..moveTo(12, 3)
        ..cubicTo(4, 3, 2, 9, 3, 14)
        ..cubicTo(4, 20, 11, 22, 14, 19)
        ..cubicTo(16, 17, 13, 15, 16, 13)
        ..cubicTo(18, 12, 21, 14, 22, 10)
        ..cubicTo(23, 6, 18, 3, 12, 3)
        ..close(),
      p,
    );
    for (final pt in const [
      Offset(8, 8),
      Offset(13, 6),
      Offset(17.5, 8.5),
      Offset(7, 13),
    ]) {
      c.drawCircle(pt, 1, f);
    }
  }

  void _globe(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 12), 9, p);
    c.drawOval(const Rect.fromLTWH(8, 3, 8, 18), p);
    _line(c, p, 3, 12, 21, 12);
    c.drawPath(
      Path()
        ..moveTo(5, 7)
        ..quadraticBezierTo(12, 10, 19, 7)
        ..moveTo(5, 17)
        ..quadraticBezierTo(12, 14, 19, 17),
      p,
    );
  }

  void _memory(Canvas c, Paint p) {
    _roundRect(c, p, const Rect.fromLTWH(5, 7, 14, 10), 2);
    for (final x in const [7.0, 10.0, 14.0, 17.0]) {
      _lines(c, p, [Offset(x, 4), Offset(x, 7), Offset(x, 17), Offset(x, 20)]);
    }
    c.drawPath(
      Path()
        ..moveTo(9, 14)
        ..lineTo(11, 10)
        ..lineTo(13, 14)
        ..lineTo(15, 10),
      p,
    );
  }

  void _storage(Canvas c, Paint p, Paint f) {
    _roundRect(c, p, const Rect.fromLTWH(3, 5, 18, 14), 3);
    _line(c, p, 3, 11, 21, 11);
    c.drawCircle(const Offset(17, 15), 1, f);
    c.drawCircle(const Offset(13.5, 15), 1, f);
  }

  void _tokens(Canvas c, Paint p) {
    c.drawCircle(const Offset(9, 9), 5, p);
    c.drawCircle(const Offset(15, 15), 5, p);
    _lines(c, p, const [
      Offset(7, 9),
      Offset(11, 9),
      Offset(15, 13),
      Offset(15, 17),
    ]);
  }

  void _cost(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 12), 9, p);
    c.drawPath(
      Path()
        ..moveTo(15, 8)
        ..cubicTo(13, 6, 9, 7, 9, 9.5)
        ..cubicTo(9, 12, 15, 11, 15, 14)
        ..cubicTo(15, 17, 10, 18, 8.5, 16),
      p,
    );
    _line(c, p, 12, 5, 12, 19);
  }

  void _link(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(9, 15)
        ..lineTo(7, 17)
        ..cubicTo(3, 21, -1, 15, 3, 11)
        ..lineTo(6, 8)
        ..cubicTo(8, 6, 11, 7, 12, 9),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(15, 9)
        ..lineTo(17, 7)
        ..cubicTo(21, 3, 25, 9, 21, 13)
        ..lineTo(18, 16)
        ..cubicTo(16, 18, 13, 17, 12, 15),
      p,
    );
    _line(c, p, 9, 15, 15, 9);
  }

  void _warning(Canvas c, Paint p, Paint f) {
    c.drawPath(
      Path()
        ..moveTo(12, 3)
        ..lineTo(22, 20)
        ..lineTo(2, 20)
        ..close(),
      p,
    );
    _line(c, p, 12, 9, 12, 14);
    c.drawCircle(const Offset(12, 17), .8, f);
  }

  void _sparkles(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(9, 3)
        ..quadraticBezierTo(9, 9, 3, 9)
        ..quadraticBezierTo(9, 9, 9, 15)
        ..quadraticBezierTo(9, 9, 15, 9)
        ..quadraticBezierTo(9, 9, 9, 3),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(17, 13)
        ..quadraticBezierTo(17, 17, 13, 17)
        ..quadraticBezierTo(17, 17, 17, 21)
        ..quadraticBezierTo(17, 17, 21, 17)
        ..quadraticBezierTo(17, 17, 17, 13),
      p,
    );
  }

  void _user(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 8), 4, p);
    c.drawPath(
      Path()
        ..moveTo(4, 21)
        ..cubicTo(4, 15, 8, 13, 12, 13)
        ..cubicTo(16, 13, 20, 15, 20, 21),
      p,
    );
  }

  void _theme(Canvas c, Paint p) {
    c.drawCircle(const Offset(12, 12), 9, p);
    c.drawPath(
      Path()
        ..moveTo(12, 3)
        ..cubicTo(7, 6, 7, 18, 12, 21)
        ..cubicTo(17, 18, 17, 6, 12, 3)
        ..close(),
      p,
    );
  }

  void _copy(Canvas c, Paint p) {
    _roundRect(c, p, const Rect.fromLTWH(8, 8, 11, 11), 2);
    c.drawPath(
      Path()
        ..moveTo(6, 16)
        ..lineTo(5, 16)
        ..quadraticBezierTo(3, 16, 3, 14)
        ..lineTo(3, 5)
        ..quadraticBezierTo(3, 3, 5, 3)
        ..lineTo(14, 3)
        ..quadraticBezierTo(16, 3, 16, 5)
        ..lineTo(16, 6),
      p,
    );
  }

  void _refresh(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(19, 8)
        ..lineTo(19, 4)
        ..lineTo(15, 4)
        ..moveTo(19, 5)
        ..cubicTo(14, 1, 6, 3, 4, 9),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(5, 16)
        ..lineTo(5, 20)
        ..lineTo(9, 20)
        ..moveTo(5, 19)
        ..cubicTo(10, 23, 18, 21, 20, 15),
      p,
    );
  }

  void _queue(Canvas c, Paint p, Paint f) {
    for (final y in const [6.0, 12.0, 18.0]) {
      c.drawCircle(Offset(5, y), 1, f);
      _line(c, p, 9, y, 20, y);
    }
  }

  void _workspace(Canvas c, Paint p) {
    _roundRect(c, p, const Rect.fromLTWH(3, 4, 18, 16), 3);
    _lines(c, p, const [
      Offset(8, 4),
      Offset(8, 20),
      Offset(8, 9),
      Offset(21, 9),
      Offset(5, 8),
      Offset(6, 8),
      Offset(5, 12),
      Offset(6, 12),
    ]);
  }

  void _tools(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(14, 5)
        ..cubicTo(16, 2, 20, 3, 21, 4)
        ..lineTo(17, 8)
        ..lineTo(14, 7)
        ..lineTo(13, 4),
      p,
    );
    _line(c, p, 14, 7, 5, 19);
    c.drawCircle(const Offset(5, 19), 2, p);
    _line(c, p, 5, 5, 19, 19);
  }

  @override
  bool shouldRepaint(covariant _SiqiIconPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
