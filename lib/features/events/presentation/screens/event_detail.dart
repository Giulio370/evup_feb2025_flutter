import 'package:flutter/material.dart';

class EventFormModal extends StatefulWidget {
  final Map<String, dynamic>? event;

  const EventFormModal({super.key, this.event});

  @override
  _EventFormModalState createState() => _EventFormModalState();
}

class _EventFormModalState extends State<EventFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.event?['description'] ?? '');
    _startTime = widget.event?['timeStart'] != null
        ? DateTime.parse(widget.event!['timeStart'])
        : null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newEvent = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'timeStart': _startTime?.toIso8601String(),
      };

      Navigator.pop(context, newEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titolo'),
              validator: (value) => value!.isEmpty ? 'Campo obbligatorio' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrizione'),
            ),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Salva Evento'),
            ),
          ],
        ),
      ),
    );
  }
}