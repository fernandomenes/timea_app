import 'package:flutter/material.dart';

import '../domain/goal.dart';

class CreateGoalSheet extends StatefulWidget {
  const CreateGoalSheet({super.key});

  @override
  State<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<CreateGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dailyTargetMinutesController = TextEditingController();

  final List<String> _iconOptions = const ['⏳', '📚', '💪', '💸', '🧠', '❤️'];

  String _selectedIcon = '⏳';
  DateTime _selectedDate = DateTime.now();
  bool _trackTime = true;
  bool _trackMoney = false;

  @override
  void dispose() {
    _titleController.dispose();
    _dailyTargetMinutesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final targetText = _dailyTargetMinutesController.text.trim();
    final dailyTargetMinutes =
        (_trackTime && targetText.isNotEmpty) ? int.tryParse(targetText) : null;

    final goal = Goal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      icon: _selectedIcon,
      startDate: _selectedDate,
      trackTime: _trackTime,
      trackMoney: _trackMoney,
      dailyTargetMinutes: dailyTargetMinutes,
    );

    Navigator.of(context).pop(goal);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Crear meta',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la meta',
                  hintText: 'Ej. Aprender inglés',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Escribe un nombre para la meta.';
                  }

                  if (value.trim().length < 3) {
                    return 'Usa al menos 3 caracteres.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Icono',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _iconOptions.map((icon) {
                  return ChoiceChip(
                    label: Text(
                      icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    selected: _selectedIcon == icon,
                    onSelected: (_) {
                      setState(() {
                        _selectedIcon = icon;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Fecha de inicio',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDate(_selectedDate),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime.now();
                          });
                        },
                        child: const Text('Hoy'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _pickDate,
                        child: const Text('Elegir'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Qué quieres medir',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _trackTime,
                onChanged: (value) {
                  setState(() {
                    _trackTime = value ?? false;

                    if (!_trackTime) {
                      _dailyTargetMinutesController.clear();
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                title: const Text('Tiempo'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _trackMoney,
                onChanged: (value) {
                  setState(() {
                    _trackMoney = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                title: const Text('Dinero'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_trackTime) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dailyTargetMinutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Objetivo diario (minutos)',
                    hintText: 'Ej. 120',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!_trackTime || value == null || value.trim().isEmpty) {
                      return null;
                    }

                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Usa un número mayor a 0.';
                    }

                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear meta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}