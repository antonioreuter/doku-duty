/// Colour vision deficiency simulation, for tests only.
///
/// Lives under `test/` rather than `lib/` because it has no runtime purpose —
/// it exists so the palette's claims about being distinguishable can be
/// asserted rather than asserted-about.
///
/// Machado, Oliveira and Fernandes (2009) transform matrices at full severity.
library;

enum ColourVision {
  protanopia(<List<double>>[
    <double>[0.152286, 1.052583, -0.204868],
    <double>[0.114503, 0.786281, 0.099216],
    <double>[-0.003882, -0.048116, 1.051998],
  ]),
  deuteranopia(<List<double>>[
    <double>[0.367322, 0.860646, -0.227968],
    <double>[0.280085, 0.672501, 0.047413],
    <double>[-0.011820, 0.042940, 0.968881],
  ]),
  tritanopia(<List<double>>[
    <double>[1.255528, -0.076749, -0.178779],
    <double>[-0.078411, 0.930809, 0.147602],
    <double>[0.004733, 0.691367, 0.303900],
  ]);

  const ColourVision(this.matrix);

  final List<List<double>> matrix;

  /// [rgb] as this form of colour vision would perceive it.
  int simulate(int rgb) {
    final channels = <double>[
      ((rgb >> 16) & 0xFF) / 255.0,
      ((rgb >> 8) & 0xFF) / 255.0,
      (rgb & 0xFF) / 255.0,
    ];
    var out = 0;
    for (var i = 0; i < 3; i++) {
      var v = 0.0;
      for (var j = 0; j < 3; j++) {
        v += matrix[i][j] * channels[j];
      }
      final byte = (v.clamp(0.0, 1.0) * 255).round();
      out = (out << 8) | byte;
    }
    return out;
  }
}
