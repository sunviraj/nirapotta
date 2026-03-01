import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/glass_container.dart';

class TriggerCustomizationScreen extends StatefulWidget {
  const TriggerCustomizationScreen({super.key});

  @override
  State<TriggerCustomizationScreen> createState() =>
      _TriggerCustomizationScreenState();
}

class _TriggerCustomizationScreenState
    extends State<TriggerCustomizationScreen> {
  // Mapping of Events to their selected Actions
  // Actions: 'sms', 'audio', 'video'
  final Map<String, List<String>> _triggerMap = {
    'shake': ['sms'],
    'loud_noise': ['sms'],
    'double_power': ['audio'],
    'triple_power': ['video'],
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    for (String trigger in _triggerMap.keys) {
      List<String>? savedActions = prefs.getStringList('trigger_$trigger');
      if (savedActions != null) {
        _triggerMap[trigger] = savedActions;
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    for (String trigger in _triggerMap.keys) {
      await prefs.setStringList('trigger_$trigger', _triggerMap[trigger]!);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trigger routines saved successfully!')),
    );
    Navigator.of(context).pop();
  }

  void _toggleAction(String event, String action) {
    setState(() {
      if (_triggerMap[event]!.contains(action)) {
        _triggerMap[event]!.remove(action);
      } else {
        _triggerMap[event]!.add(action);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Custom Logic Engine',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Actions',
            onPressed: _isLoading ? null : _savePreferences,
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
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        opacity: 0.1,
                        border: Border.all(color: Colors.white10),
                        child: const Row(
                          children: [
                            Icon(Icons.hub, color: Colors.blueAccent, size: 28),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Bind physical actions to emergency responses. Choose what happens when each event occurs.',
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
                        child: ListView(
                          children: [
                            _buildTriggerCard(
                                'Shake Detected', 'shake', Icons.vibration),
                            _buildTriggerCard('Loud Noise (Scream)',
                                'loud_noise', Icons.mic_none),
                            _buildTriggerCard('Double Power Button',
                                'double_power', Icons.power_settings_new),
                            _buildTriggerCard('Triple Power Button',
                                'triple_power', Icons.flash_on),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _savePreferences,
                          child: Text(
                            'SAVE LOGIC MATRIX',
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTriggerCard(String title, String triggerKey, IconData icon) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      opacity: 0.05,
      border: Border.all(color: Colors.white10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 24),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          _buildActionCheckbox(triggerKey, 'sms', 'Send SMS with Location'),
          _buildActionCheckbox(triggerKey, 'audio', 'Start Background Audio'),
          _buildActionCheckbox(triggerKey, 'video', 'Start Background Video'),
        ],
      ),
    );
  }

  Widget _buildActionCheckbox(
      String triggerKey, String actionKey, String label) {
    bool isSelected = _triggerMap[triggerKey]!.contains(actionKey);
    return CheckboxListTile(
      title: Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 14)),
      value: isSelected,
      onChanged: (bool? value) {
        _toggleAction(triggerKey, actionKey);
      },
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.blueAccent,
      checkColor: Colors.white,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
