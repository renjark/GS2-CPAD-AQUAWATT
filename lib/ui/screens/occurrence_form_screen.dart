import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/core/validators.dart';
import 'package:aquawatt/data/regions_seed.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/state/app_state.dart';
import 'package:aquawatt/state/occurrences_controller.dart';
import 'package:aquawatt/ui/widgets/app_dropdown_field.dart';
import 'package:aquawatt/ui/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Formulário de ocorrência anônima do cidadão, com validação e feedback de erro.
class OccurrenceFormScreen extends StatefulWidget {
  const OccurrenceFormScreen({super.key});

  @override
  State<OccurrenceFormScreen> createState() => _OccurrenceFormScreenState();
}

class _OccurrenceFormScreenState extends State<OccurrenceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  OccurrenceCategory? _category;
  late String _regionId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _regionId = context.read<AppState>().selectedRegionId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await context.read<OccurrencesController>().add(
          regionId: _regionId,
          category: _category!,
          description: _descriptionController.text,
        );
    messenger.showSnackBar(
      const SnackBar(content: Text('Ocorrência registrada de forma anônima.')),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ocorrência')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Seu relato é anônimo: não pedimos nome, contato nem localização exata. '
                'Ele fica salvo apenas neste dispositivo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdownField<OccurrenceCategory>(
                label: 'Tipo de ocorrência',
                value: _category,
                items: OccurrenceCategory.values,
                labelOf: (c) => c.label,
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => Validators.requiredChoice(v, message: 'Escolha o tipo de ocorrência.'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdownField<Region>(
                label: 'Bairro',
                value: regionById(_regionId),
                items: kRegions,
                labelOf: (r) => r.name,
                onChanged: (v) => setState(() => _regionId = v?.id ?? _regionId),
                validator: (v) => Validators.requiredChoice(v, message: 'Escolha o bairro.'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Descrição',
                hint: 'Ex.: vazamento constante na calçada há dois dias',
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 280,
                keyboardType: TextInputType.multiline,
                validator: Validators.description,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: const Icon(Icons.send_outlined),
                label: Text(_submitting ? 'Registrando…' : 'Registrar ocorrência'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
