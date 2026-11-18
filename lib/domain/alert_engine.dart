import 'dart:math' as math;

import 'package:aquawatt/core/formatters.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/domain/stats.dart';

/// Resumo estatístico de uma série de consumo (últimos 7 dias vs. linha de base).
class ConsumptionSummary {
  ConsumptionSummary({
    required this.recentMean,
    required this.baseMean,
    required this.baselineDays,
    required this.baseCv,
    required this.fit,
  });

  final double recentMean;
  final double baseMean;
  final int baselineDays;

  /// Coeficiente de variação da linha de base (desvio padrão / média).
  final double baseCv;

  /// Ajuste linear dos últimos 14 dias.
  final LinearFit fit;

  double get deviation => (recentMean - baseMean) / baseMean;
  double get slope => fit.slope;
  double get r2 => fit.r2;

  /// Projeção linear [daysAhead] dias após o último dia observado.
  double forecast(int daysAhead) => fit.predict(13.0 + daysAhead);

  /// Heurística: metade ajuste linear (R²), metade estabilidade da linha de base.
  double get confidence =>
      (0.5 * r2 + 0.5 * (1 - math.min(baseCv * 5, 1))).clamp(0.1, 0.95).toDouble();

  static ConsumptionSummary? from(List<double> series) {
    if (series.length < 21) return null;
    final base = series.sublist(0, series.length - 7);
    final recent = series.sublist(series.length - 7);
    final baseMean = mean(base);
    if (baseMean <= 0) return null;
    return ConsumptionSummary(
      recentMean: mean(recent),
      baseMean: baseMean,
      baselineDays: base.length,
      baseCv: stdDev(base) / baseMean,
      fit: linearFit(series.sublist(series.length - 14)),
    );
  }
}

/// Gera alertas explicáveis a partir de regras sobre os dados. Função pura.
class AlertEngine {
  const AlertEngine();

  List<AlertItem> generate({
    required List<Region> regions,
    required Map<String, List<DailyReading>> readings,
    required Map<String, List<WeatherDay>> weather,
    required Thresholds thresholds,
    required List<Occurrence> occurrences,
    required DateTime now,
    DateTime? weatherUpdatedAt,
  }) {
    final alerts = <AlertItem>[];
    for (final region in regions) {
      final data = readings[region.id];
      if (data != null) {
        final water = _consumption(
            region, Metric.water, data.map((e) => e.water).toList(), thresholds.waterFraction, now);
        if (water != null) alerts.add(water);
        final energy = _consumption(region, Metric.energy,
            data.map((e) => e.energy).toList(), thresholds.energyFraction, now);
        if (energy != null) alerts.add(energy);
      }
      final leak = _leaks(region, occurrences, now);
      if (leak != null) alerts.add(leak);
    }
    alerts.addAll(_climate(weather, thresholds, now, weatherUpdatedAt));
    alerts.sort((a, b) {
      final bySeverity = b.severity.index.compareTo(a.severity.index);
      return bySeverity != 0 ? bySeverity : b.confidence.compareTo(a.confidence);
    });
    return alerts;
  }

  AlertItem? _consumption(
      Region region, Metric metric, List<double> series, double limit, DateTime now) {
    final s = ConsumptionSummary.from(series);
    if (s == null || s.deviation < limit) return null;

    final unit = metric.unit;
    final name = metric == Metric.water ? 'água' : 'energia';
    final sign = s.slope >= 0 ? '+' : '';
    final severity = s.deviation >= limit * 1.5 ? Severity.high : Severity.medium;

    return AlertItem(
      id: '${region.id}-${metric.name}-consumo',
      regionId: region.id,
      metric: metric,
      severity: severity,
      title: 'Consumo de $name acima do esperado',
      summary: 'Em ${region.name}, a média dos últimos 7 dias está '
          '${fmtPct(s.deviation, signed: false)} acima da linha de base. '
          'Se a tendência atual se mantiver, o consumo pode chegar a '
          '${fmt(s.forecast(3))} $unit em 3 dias.',
      evidence: [
        'Média dos últimos 7 dias: ${fmt(s.recentMean)} $unit, contra '
            '${fmt(s.baseMean)} $unit na linha de base '
            '(${s.baselineDays} dias anteriores): ${fmtPct(s.deviation)}.',
        'Limiar configurado para disparar este alerta: +${fmt(limit * 100, 0)}%.',
        'Tendência linear dos últimos 14 dias: $sign${fmt(s.slope, 2)} $unit por dia '
            '(R² = ${fmt(s.r2, 2)}).',
      ],
      confidence: s.confidence,
      confidenceNote: 'Combina o ajuste linear (R² = ${fmt(s.r2, 2)}) com a estabilidade '
          'histórica da linha de base (variação de ${fmtPct(s.baseCv, signed: false)}). '
          'É uma heurística, não uma probabilidade estatística calibrada.',
      limitations: [
        'Dados sintéticos de demonstração: não representam medições reais de '
            'companhias de água ou energia.',
        'Modelo linear simples sobre 14 dias: não captura sazonalidade, feriados '
            'nem mudanças bruscas.',
        'A linha de base cobre só ${s.baselineDays} dias e pode refletir um período atípico.',
        'Aumentos podem ter causas legítimas (eventos, obras, mais moradores); '
            'o alerta não indica a causa.',
        'Com R² baixo (< 0,30) ou alta variação histórica, a projeção perde confiabilidade.',
      ],
      suggestedAction: metric == Metric.water
          ? 'Verificar hidrômetros e a rede do bairro em busca de vazamentos antes de '
              'qualquer medida; considerar uma campanha de uso consciente.'
          : 'Revisar picos de demanda no bairro e avaliar uma campanha de eficiência energética.',
      createdAt: now,
    );
  }

  AlertItem? _leaks(Region region, List<Occurrence> occurrences, DateTime now) {
    final cutoff = now.subtract(const Duration(days: 7));
    final count = occurrences
        .where((o) =>
            o.regionId == region.id &&
            o.category == OccurrenceCategory.waterLeak &&
            o.createdAt.isAfter(cutoff))
        .length;
    if (count < 2) return null;

    return AlertItem(
      id: '${region.id}-water-vazamentos',
      regionId: region.id,
      metric: Metric.water,
      severity: count >= 4 ? Severity.medium : Severity.low,
      title: 'Relatos de vazamento em ${region.name}',
      summary: '$count cidadãos relataram vazamento de água nos últimos 7 dias.',
      evidence: [
        '$count relatos de vazamento em 7 dias (registros anônimos feitos no app).',
        'Regra: dois ou mais relatos na mesma semana geram o alerta.',
      ],
      confidence: math.min(0.2 + 0.1 * count, 0.6),
      confidenceNote: 'Baixa por construção: relatos de cidadãos não são verificados. '
          'A confiança sobe 10 pontos por relato, até o máximo de 60%.',
      limitations: [
        'Relatos não são verificados e podem estar duplicados.',
        'Viés de cobertura: bairros com menos acesso ao app geram menos relatos.',
        'Poucos relatos podem indicar o mesmo problema ou problemas distintos.',
      ],
      suggestedAction: 'Confirmar os relatos com uma equipe de campo antes de acionar reparos.',
      createdAt: now,
    );
  }

  List<AlertItem> _climate(
    Map<String, List<WeatherDay>> weather,
    Thresholds thresholds,
    DateTime now,
    DateTime? weatherUpdatedAt,
  ) {
    if (weather.isEmpty) return const [];
    final today = dateOnly(now);
    final tempByLead = List.generate(3, (_) => <double>[]);
    final rainByLead = List.generate(3, (_) => <double>[]);

    for (final days in weather.values) {
      final upcoming = days.where((d) => !d.date.isBefore(today)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      for (var i = 0; i < math.min(3, upcoming.length); i++) {
        tempByLead[i].add(upcoming[i].tMax);
        rainByLead[i].add(upcoming[i].precipitation);
      }
    }

    final temps = [for (final l in tempByLead) if (l.isNotEmpty) mean(l)];
    final rains = [for (final l in rainByLead) if (l.isNotEmpty) mean(l)];
    if (temps.isEmpty) return const [];

    final updatedAt = weatherUpdatedAt;
    final staleNote = (updatedAt != null && now.difference(updatedAt) > const Duration(hours: 6))
        ? ['Previsão salva em ${fmtDateTime(updatedAt)} (modo offline): pode estar desatualizada.']
        : const <String>[];
    const leadLabels = ['hoje', 'amanhã', 'em 2 dias'];
    final alerts = <AlertItem>[];

    final maxTemp = temps.reduce(math.max);
    if (maxTemp >= thresholds.heatC) {
      final lead = temps.indexOf(maxTemp);
      alerts.add(AlertItem(
        id: '$kTerritoryId-calor',
        regionId: kTerritoryId,
        metric: Metric.climate,
        severity: maxTemp >= thresholds.heatC + 3 ? Severity.high : Severity.medium,
        title: 'Calor intenso previsto',
        summary: 'Máxima média prevista de ${fmt(maxTemp)} °C ${leadLabels[lead]}. '
            'Calor tende a elevar a demanda por energia e o consumo de água.',
        evidence: [
          'Média das previsões dos bairros para ${leadLabels[lead]}: ${fmt(maxTemp)} °C '
              '(limiar configurado: ${fmt(thresholds.heatC, 0)} °C).',
          'Fonte: previsão de 3 dias da Open-Meteo para o ponto central de cada bairro.',
        ],
        confidence: 0.85 - 0.08 * lead,
        confidenceNote: 'Heurística pela antecedência da previsão: 85% para hoje, '
            'reduzindo 8 pontos por dia de antecedência.',
        limitations: [
          'Previsão em grade de alguns quilômetros: microclimas e ilhas de calor locais podem diferir.',
          'A relação calor → demanda é uma hipótese; não foi calibrada com dados reais.',
          'A confiança diminui quanto mais distante é o dia previsto.',
          ...staleNote,
        ],
        suggestedAction: 'Reforçar a comunicação de uso consciente de energia e água e '
            'atenção a grupos vulneráveis, a critério do gestor.',
        createdAt: now,
      ));
    }

    final rainTotal = rains.fold<double>(0, (a, b) => a + b);
    if (rains.isNotEmpty && rainTotal >= thresholds.rainMm) {
      alerts.add(AlertItem(
        id: '$kTerritoryId-chuva',
        regionId: kTerritoryId,
        metric: Metric.climate,
        severity: rainTotal >= thresholds.rainMm * 1.5 ? Severity.high : Severity.medium,
        title: 'Chuva volumosa prevista',
        summary: 'Acumulado médio previsto de ${fmt(rainTotal)} mm em até 3 dias, '
            'o que pode aumentar a demanda por serviços de drenagem.',
        evidence: [
          'Soma das médias diárias previstas: ${fmt(rainTotal)} mm '
              '(limiar configurado: ${fmt(thresholds.rainMm, 0)} mm).',
          'Fonte: previsão de 3 dias da Open-Meteo para o ponto central de cada bairro.',
        ],
        confidence: 0.55,
        confidenceNote: 'Valor fixo de 55%: a precipitação é menos previsível que a temperatura.',
        limitations: [
          'Chuva é muito variável no espaço; o volume em cada rua pode ser bem diferente.',
          'O alerta não considera a capacidade real de drenagem de cada bairro.',
          ...staleNote,
        ],
        suggestedAction: 'Verificar pontos de drenagem e preparar equipes; avisar a Defesa Civil '
            'se o gestor julgar necessário.',
        createdAt: now,
      ));
    }
    return alerts;
  }
}
