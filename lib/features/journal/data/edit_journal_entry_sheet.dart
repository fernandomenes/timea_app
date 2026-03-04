import 'package:flutter/material.dart';

import '../../goals/domain/goal.dart';
import '../domain/journal_entry.dart';

class EditJournalEntrySheet extends StatefulWidget {
  const EditJournalEntrySheet({
    super.key,
    required this.goal,
    required this.entry,
  });

  final Goal goal;
  final JournalEntry entry;

  @override
  State<EditJournalEntrySheet> createState() => _EditJournalEntrySheetState();
}

class _EditJournalEntrySheetState extends State<EditJournalEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController;
  late final TextEditingController _minutesController;
  late final TextEditingController _moneyController;

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.entry.date;
    _textController = TextEditingController(text: widget.entry.text);
    _minutesController = TextEditingController(
      text: widget.entry.minutesSpent?.toString() ?? '',
    );
    _moneyController = TextEditingController(
      text: widget.entry.moneySpent?.toString() ?? '',
    );
  }

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

    final updated = JournalEntry(
      id: widget.entry.id,
      goalId: widget.entry.goalId,
      date: _selectedDate,
      text: _textController.text.trim(),
      minutesSpent: minutesText.isEmpty ? null : int.tryParse(minutesText),
      moneySpent: moneyText.isEmpty ? null : double.tryParse(moneyText),
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
                'Editar registro',
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