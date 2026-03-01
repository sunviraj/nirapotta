import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/glass_container.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final List<TextEditingController> _controllers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedContacts =
        prefs.getStringList('emergency_contacts') ?? [];

    if (savedContacts.isEmpty) {
      // Start with one empty slot
      _controllers.add(TextEditingController());
    } else {
      for (var contact in savedContacts) {
        _controllers.add(TextEditingController(text: contact));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveContacts() async {
    List<String> validContacts = [];
    for (var controller in _controllers) {
      String text = controller.text.trim();
      if (text.isNotEmpty) {
        validContacts.add(text);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('emergency_contacts', validContacts);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency contacts saved successfully!')),
    );
    Navigator.of(context).pop();
  }

  void _addContactField() {
    if (_controllers.length < 5) {
      setState(() {
        _controllers.add(TextEditingController());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 contacts allowed.')),
      );
    }
  }

  void _removeContactField(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      if (_controllers.isEmpty) {
        _controllers.add(TextEditingController());
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Emergency Contacts',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveContacts,
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1E1E), Color(0xFF2D1B2E)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        opacity: 0.1,
                        border: Border.all(color: Colors.white10),
                        child: const Row(
                          children: [
                            Icon(Icons.contact_phone,
                                color: Colors.blueAccent, size: 28),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Add up to 5 phone numbers that will receive SMS alerts with your location when triggered.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _controllers.length,
                          itemBuilder: (context, index) {
                            return GlassContainer(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controllers[index],
                                      keyboardType: TextInputType.phone,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Enter Phone Number',
                                        hintStyle: const TextStyle(
                                            color: Colors.white30),
                                        border: InputBorder.none,
                                        icon: const Icon(Icons.phone,
                                            color: Colors.white54),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.redAccent),
                                    onPressed: () => _removeContactField(index),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_controllers.length < 5)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add, color: Colors.blueAccent),
                          label: const Text('ADD ANOTHER CONTACT',
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold)),
                          onPressed: _addContactField,
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _saveContacts,
                        child: const Text(
                          'SAVE CONTACTS',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
