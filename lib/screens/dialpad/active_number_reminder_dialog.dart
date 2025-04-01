import 'package:flutter/material.dart';

class ActiveNumberReminderDialog extends StatelessWidget {
  final VoidCallback onNavigateToSettings;

  const ActiveNumberReminderDialog({
    super.key,
    required this.onNavigateToSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.phone_missed,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 12),
          Text('No Active Number Selected'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You need to select an active phone number to make calls and send messages.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can set your active number from Settings > Communication > Phone Numbers',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('LATER'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onNavigateToSettings();
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('GO TO SETTINGS'),
        ),
      ],
      actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
