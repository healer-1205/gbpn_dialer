// Phone number selection screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/properties/phone.dart';
import 'package:gbpn_dealer/models/auth_response.dart';
import 'package:gbpn_dealer/services/storage_service.dart';

class PhoneNumberSelectionScreen extends StatefulWidget {
  const PhoneNumberSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PhoneNumberSelectionScreen> createState() =>
      _PhoneNumberSelectionScreenState();
}

class _PhoneNumberSelectionScreenState
    extends State<PhoneNumberSelectionScreen> {
  // Currently selected team index
  int _selectedTeamIndex = 0;

  // Currently selected phone number ID
  int? _selectedPhoneNumberId;
  final StorageService _storageService = StorageService();
  // Mock data for teams
  List<Team> _teams = [];
  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    final authResponse = await _storageService.getAuthResponse();
    final List<Team> fetchedTeams = authResponse?.teams ?? [];
    final selectedPhoneNumber = await _storageService.getActivePhoneNumber();
    setState(() {
      _teams = fetchedTeams;
      if (_teams.isEmpty) return;
      _selectedPhoneNumberId =
          selectedPhoneNumber?.id ?? _teams[0].phoneNumbers[0].id;
    });
    if (selectedPhoneNumber == null && _teams.isNotEmpty) {
      await _storageService.saveActivePhoneNumber(_teams[0].phoneNumbers[0]);
    }
  }

  Future<void> _updateActivePhoneNumber(PhoneNumber phoneNumber) async {
    await _storageService.saveActivePhoneNumber(phoneNumber);
    setState(() {
      _selectedPhoneNumberId = phoneNumber.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Phone Number'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Team selector
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.primaryContainer.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Team',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (_teams.isNotEmpty)
                  Container(
                    height: 50,
                    child: DropdownButtonFormField<int>(
                      value: _selectedTeamIndex,
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      icon: Icon(Icons.arrow_drop_down),
                      isExpanded: true,
                      items: _teams.asMap().entries.map((entry) {
                        return DropdownMenuItem<int>(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(Icons.group_work_outlined),
                              SizedBox(width: 12),
                              Text(entry.value.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTeamIndex = newValue;
                          });
                        }
                      },
                    ),
                  )
              ],
            ),
          ),
          if (_teams.isNotEmpty)
            // Phone numbers list
            Expanded(
              child: ListView.builder(
                itemCount: _teams[_selectedTeamIndex].phoneNumbers.length,
                itemBuilder: (context, index) {
                  final phoneNumber =
                      _teams[_selectedTeamIndex].phoneNumbers[index];
                  final bool isSelected =
                      phoneNumber.id == _selectedPhoneNumberId;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: isSelected ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? BorderSide(color: colorScheme.primary, width: 2)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPhoneNumberId = phoneNumber.id;
                        });
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        // Show confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Set ${phoneNumber.friendlyName} as active'),
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () {
                                // Restore previous selection
                                setState(() {
                                  _selectedPhoneNumberId =
                                      _selectedPhoneNumberId;
                                });
                              },
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.surfaceVariant,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.phone,
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    phoneNumber.friendlyName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    phoneNumber.name,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    phoneNumber.phoneNumber,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) =>
                                        _buildPhoneOptionsSheet(
                                            context,
                                            phoneNumber,
                                            _updateActivePhoneNumber),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhoneOptionsSheet(BuildContext context, PhoneNumber phoneNumber,
      ValueChanged<PhoneNumber> onPhoneNumberSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Set as Active'),
            onTap: () {
              Navigator.pop(context);
              onPhoneNumberSelected(phoneNumber);
            },
          ),
          ListTile(
            leading: const Icon(Icons.content_copy),
            title: const Text('Copy Number'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: phoneNumber.phoneNumber));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
