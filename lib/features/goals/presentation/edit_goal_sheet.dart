import 'package:flutter/material.dart';

import '../domain/goal.dart';

class EditGoalSheet extends StatefulWidget {
  const EditGoalSheet({
    super.key,
    required this.goal,
  });

  final Goal goal;

  @override
  State<EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends State<EditGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _dailyTargetMinutesController;

  final List<String> _iconOptions = const ['⏳', '📚', '💪', '💸', '🧠', '❤️'];

  late String _selectedIcon;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _dailyTargetMinutesController = TextEditingController(
      text: widget.goal.dailyTargetMinutes?.toString() ?? '',
    );

    _selectedIcon = widget.goal.icon;
    _selectedDate = widget.goal.startDate;
  }

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
    final dailyTargetMinutes = (widget.goal.trackTime && targetText.isNotEmpty)
        ? int.tryParse(targetText)
        : null;

    final updated = Goal(
      id: widget.goal.id,
      title: _titleController.text.trim(),
      icon: _selectedIcon,
      startDate: _selectedDate,
      trackTime: widget.goal.trackTime,
      trackMoney: widget.goal.trackMoney,
      dailyTargetMinutes: dailyTargetMinutes,
    );

    Navigator.of(context).pop(updated);
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
                'Editar meta',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la meta',
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
                    label: Text(icon, style: const TextStyle(fontSize: 20)),
                    selected: _selectedIcon == icon,
                    onSelected: (_) => setState(() => _selectedIcon = icon),
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
                        onPressed: () => setState(() => _selectedDate = DateTime.now()),
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
              if (widget.goal.trackTime) ...[
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
                    if (value == null || value.trim().isEmpty) return null;
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Usa un número mayor a 0.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}