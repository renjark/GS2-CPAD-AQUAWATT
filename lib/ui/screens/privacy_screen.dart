import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/ui/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// Política de privacidade e recursos de acessibilidade, em linguagem simples.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = <({String title, List<String> items})>[
    (
      title: 'Dados que coletamos',
      items: [
        'Nenhum dado pessoal: sem nome, e-mail, telefone, CPF ou localização exata.',
        'Ocorrências: tipo, bairro, descrição e data. São anônimas e ficam só no seu dispositivo.',
        'Preferências: tema, tamanho do texto, bairro selecionado e limiares de alerta.',
      ],
    ),
    (
      title: 'Proteções',
      items: [
        'O formulário recusa textos com e-mail, telefone ou CPF.',
        'O consentimento é pedido na primeira abertura e pode ser revogado a qualquer momento.',
        'Revogar o consentimento apaga todas as ocorrências, decisões e preferências locais.',
      ],
    ),
    (
      title: 'Serviços externos',
      items: [
        'Open-Meteo (clima): recebe apenas as coordenadas do ponto central de cada bairro, '
            'nunca a sua posição.',
        'OpenStreetMap (mapa): serve as imagens do mapa e pode registrar o endereço de rede '
            'do aparelho, como qualquer site.',
        'Os dados de consumo de água e energia são sintéticos, gerados no próprio app.',
      ],
    ),
    (
      title: 'Acessibilidade',
      items: [
        'Textos ampliáveis (ajuste do sistema e do app).',
        'Temas claro, escuro e de alto contraste.',
        'Descrições para leitores de tela em cartões, gráficos e botões.',
        'Severidade indicada por ícone e texto, nunca só por cor.',
        'Áreas de toque de pelo menos 48 pixels.',
      ],
    ),
    (
      title: 'Decisão humana',
      items: [
        'Os alertas são apoio à decisão. O app não executa nenhuma ação automática: '
            'apenas registra o parecer de uma pessoa.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e acessibilidade')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (final section in _sections) ...[
            Semantics(
              header: true,
              child: Text(section.title, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in section.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6, right: AppSpacing.sm),
                            child: Icon(Icons.circle, size: 6),
                          ),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
