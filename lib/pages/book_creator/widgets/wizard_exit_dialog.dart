import 'package:flutter/material.dart';
import '../../../services/preference_service.dart';

class WizardExitDialog extends StatefulWidget {
  const WizardExitDialog({super.key});

  @override
  State<WizardExitDialog> createState() => _WizardExitDialogState();
}

class _WizardExitDialogState extends State<WizardExitDialog> {
  bool _dontAskAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 12),
          Text('Exit Wizard?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Are you sure you want to leave the page content wizard? '
            'Unsaved changes will be lost.',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _dontAskAgain,
            onChanged: (value) {
              setState(() => _dontAskAgain = value ?? false);
            },
            title: const Text(
              "Don't ask me again",
              style: TextStyle(fontSize: 14),
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_dontAskAgain) {
              final prefs = PreferencesService();
              await prefs.setShowWizardExitConfirmation(false);
            }
            if (context.mounted) {
              Navigator.pop(context, true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Exit Anyway'),
        ),
      ],
    );
  }
}