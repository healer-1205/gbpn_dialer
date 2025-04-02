import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({required this.onMakeCall, super.key});
  final ValueChanged<String> onMakeCall;
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  List<Contact> _contacts = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _contacts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _contacts.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey.shade300, // Color of the divider
                thickness: 1, // Thickness of the divider
                indent: 20, // Left padding
                endIndent: 20, // Right padding
              ),
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return ListTile(
                  title: Text(contact.displayName),
                  subtitle: contact.phones.isNotEmpty
                      ? Text(contact.phones.first.number)
                      : Text("No phone number"),
                  onTap: () {
                    if (contact.phones.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("No phone number")),
                      );
                      return;
                    }
                    widget.onMakeCall(contact.phones.first.number);
                  },
                );
              },
            ),
    );
  }

  Future<void> _fetchContacts() async {
    if (await requestContactPermission()) {
      List<Contact> contacts =
          await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        _contacts = contacts;
      });
    } else {
      print("Permission denied");
    }
  }

  Future<bool> requestContactPermission() async {
    var status = await Permission.contacts.request();
    return status.isGranted;
  }
}
