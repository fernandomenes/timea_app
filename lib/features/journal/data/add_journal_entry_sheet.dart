import 'package:flutter/material.dart';

import '../../goals/domain/goal.dart';
import '../domain/journal_entry.dart';

class AddJournalEntrySheet extends StatefulWidget {
  const AddJournalEntrySheet({
    super.key,
    required this.goal,
  });

  final Goal goal;

  @override
  State<AddJournalEntrySheet> createState() => _AddJournalEntrySheetState();
}

class _AddJournalEntrySheetState extends State<AddJournalEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _minutesController = TextEditingController();
  final _moneyController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _textController.dispose();
    _minutesController.dispose();
    _moneyController.dispose();
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

    final minutesText = _minutesController.text.trim();
    final moneyText = _moneyController.text.trim();

    final minutesSpent = minutesText.isEmpty ? null : int.tryParse(minutesText);
    final moneySpent = moneyText.isEmpty ? null : double.tryParse(moneyText);

    final entry = JournalEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      goalId: widget.goal.id,
      date: _selectedDate,
      text: _textController.text.trim(),
      minutesSpent: minutesSpent,
      moneySpent: moneySpent,
    );

    Navigator.of(context).pop(entry);
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
                'Agregar registro',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _textController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Nota del día',
                  hintText: '¿Qué hiciste hoy? ¿Cómo te fue?',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Escribe una nota para este registro.';
                  }

                  return null;
                },
              ),
              if (widget.goal.trackTime) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minutos invertidos',
                    hintText: 'Ej. 45',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;

                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Usa un número válido.';
                    }

                    return null;
                  },
                ),
              ],
              if (widget.goal.trackMoney) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _moneyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Dinero invertido',
                    hintText: 'Ej. 120.50',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;

                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Usa un número válido.';
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
                  label: const Text('Guardar registro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}