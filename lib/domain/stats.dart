import 'dart:math' as math;

double mean(List<double> values) =>
    values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;

double stdDev(List<double> values) {
  if (values.length < 2) return 0;
  final m = mean(values);
  final sum = values.fold<double>(0, (acc, x) => acc + (x - m) * (x - m));
  return math.sqrt(sum / (values.length - 1));
}

/// Regressão linear simples com x = 0..n-1.
class LinearFit {
  LinearFit(this.slope, this.intercept, this.r2);

  final double slope;
  final double intercept;

  /// Coeficiente de determinação (0 a 1).
  final double r2;

  double predict(double x) => intercept + slope * x;
}

LinearFit linearFit(List<double> y) {
  final n = y.length;
  if (n < 2) return LinearFit(0, n == 1 ? y.first : 0, 0);
  final xm = (n - 1) / 2;
  final ym = mean(y);
  var sxy = 0.0;
  var sxx = 0.0;
  var syy = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = i - xm;
    final dy = y[i] - ym;
    sxy += dx * dy;
    sxx += dx * dx;
    syy += dy * dy;
  }
  final slope = sxx == 0 ? 0.0 : sxy / sxx;
  final intercept = ym - slope * xm;
  final r2 = (sxx == 0 || syy == 0) ? 0.0 : (sxy * sxy) / (sxx * syy);
  return LinearFit(slope, intercept, r2);
}
