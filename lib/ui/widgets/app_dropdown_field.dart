import 'package:flutter/material.dart';

/// Dropdown de formulário padronizado, com validação e mensagem de erro.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.value,
    this.validator,
  });

  final String label;
  final List<T> items;
  final String Function(T item) labelOf;
  final ValueChanged<T?> onChanged;
  final T? value;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: ValueKey(value),
      initialValue: value,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (state) => InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: state.errorText,
          errorMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: state.value,
            isExpanded: true,
            hint: const Text('Selecione'),
            items: [
              for (final item in items)
                DropdownMenuItem<T>(value: item, child: Text(labelOf(item))),
            ],
            onChanged: (v) {
              state.didChange(v);
              onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}
