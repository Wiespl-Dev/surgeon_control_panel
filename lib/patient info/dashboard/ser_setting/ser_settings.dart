import 'package:flutter/material.dart';

class SurgerySettingsPage extends StatefulWidget {
  const SurgerySettingsPage({super.key});

  @override
  State<SurgerySettingsPage> createState() => _SurgerySettingsPageState();
}

class _SurgerySettingsPageState extends State<SurgerySettingsPage> {
  // Define the custom colors
  final Color _primaryColor = const Color.fromARGB(255, 112, 143, 214);
  final Color _secondaryColor = const Color.fromARGB(255, 157, 102, 228);

  // Settings state
  bool _enableSurgeryNotifications = true;
  bool _enablePreOpChecklist = true;
  bool _enablePostOpMonitoring = true;
  bool _enableSurgeryAuditLog = false;
  bool _autoGenerateSurgeryReports = true;
  bool _requireSurgeryConfirmation = true;

  int _surgeryReminderTime = 30; // minutes
  int _maxSurgeriesPerDay = 4;
  int _defaultSurgeryDuration = 60; // minutes

  String _defaultTheater = 'Operating Room 1';
  final List<String> _theaterOptions = [
    'Operating Room 1',
    'Operating Room 2',
    'Operating Room 3',
    'Cardiac OR',
    'Neuro OR',
    'Ortho OR',
  ];

  String _anesthesiaDefault = 'General';
  final List<String> _anesthesiaOptions = [
    'General',
    'Regional',
    'Local',
    'Sedation',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Surgery Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 40, 123, 131),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 40, 123, 131),
              Color.fromARGB(255, 39, 83, 87),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Settings
              _buildSectionHeader('Notification Settings'),
              _buildSwitchSetting(
                'Surgery Notifications',
                'Receive alerts for upcoming surgeries',
                _enableSurgeryNotifications,
                (value) => setState(() => _enableSurgeryNotifications = value),
              ),
              // _buildSliderSetting(
              //   'Reminder Time (minutes)',
              //   _surgeryReminderTime,
              //   5,
              //   120,
              //   (value) => setState(() => _surgeryReminderTime = value.round()),
              // ),

              // Surgery Configuration
              _buildSectionHeader('Surgery Configuration'),
              _buildSwitchSetting(
                'Pre-Op Checklist',
                'Require completion of pre-operative checklist',
                _enablePreOpChecklist,
                (value) => setState(() => _enablePreOpChecklist = value),
              ),
              _buildSwitchSetting(
                'Post-Op Monitoring',
                'Enable post-operative monitoring alerts',
                _enablePostOpMonitoring,
                (value) => setState(() => _enablePostOpMonitoring = value),
              ),
              _buildSwitchSetting(
                'Require Confirmation',
                'Require confirmation before starting surgery',
                _requireSurgeryConfirmation,
                (value) => setState(() => _requireSurgeryConfirmation = value),
              ),

              // Default Values
              _buildSectionHeader('Default Values'),
              _buildDropdownSetting(
                'Default Operating Theater',
                _defaultTheater,
                _theaterOptions,
                (value) => setState(() => _defaultTheater = value!),
              ),
              _buildDropdownSetting(
                'Default Anesthesia',
                _anesthesiaDefault,
                _anesthesiaOptions,
                (value) => setState(() => _anesthesiaDefault = value!),
              ),
              _buildSliderSetting(
                'Default Surgery Duration (minutes)',
                _defaultSurgeryDuration.toDouble(),
                15,
                240,
                (value) =>
                    setState(() => _defaultSurgeryDuration = value.round()),
              ),
              _buildSliderSetting(
                'Max Surgeries Per Day',
                _maxSurgeriesPerDay.toDouble(),
                1,
                8,
                (value) => setState(() => _maxSurgeriesPerDay = value.round()),
              ),

              // Reporting & Logging
              _buildSectionHeader('Reporting & Logging'),
              _buildSwitchSetting(
                'Auto-generate Reports',
                'Automatically generate surgery reports',
                _autoGenerateSurgeryReports,
                (value) => setState(() => _autoGenerateSurgeryReports = value),
              ),
              _buildSwitchSetting(
                'Surgery Audit Log',
                'Maintain detailed audit log of all surgery actions',
                _enableSurgeryAuditLog,
                (value) => setState(() => _enableSurgeryAuditLog = value),
              ),

              // Emergency Settings
              _buildSectionHeader('Emergency Protocols'),
              _buildEmergencyProtocols(),

              // Save and Reset Buttons
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetToDefaults,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reset to Defaults',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _primaryColor,
          activeTrackColor: _primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title: ${value.round()}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              label: value.round().toString(),
              onChanged: onChanged,
              activeColor: _primaryColor,
              inactiveColor: _primaryColor.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: title,
            labelStyle: TextStyle(color: _primaryColor),
            border: InputBorder.none,
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _primaryColor),
            ),
          ),
          items: options.map((String option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          style: TextStyle(color: Colors.grey[800]),
        ),
      ),
    );
  }

  Widget _buildEmergencyProtocols() {
    return Column(
      children: [
        _buildEmergencyProtocolItem(
          'Code Blue',
          'Cardiac Arrest Protocol',
          Colors.red,
        ),
        _buildEmergencyProtocolItem(
          'Rapid Response',
          'Patient Deterioration',
          Colors.orange,
        ),
        _buildEmergencyProtocolItem(
          'Fire Emergency',
          'OR Fire Protocol',
          Colors.amber[700]!,
        ),
        _buildEmergencyProtocolItem(
          'Mass Casualty',
          'Disaster Response',
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildEmergencyProtocolItem(
    String title,
    String subtitle,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.withOpacity(0.9),
      child: ListTile(
        leading: Icon(Icons.warning, color: Colors.white),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.9)),
        ),
        trailing: IconButton(
          icon: Icon(Icons.arrow_forward, color: Colors.white),
          onPressed: () => _viewEmergencyProtocol(title),
        ),
      ),
    );
  }

  void _saveSettings() {
    // Here you would typically save settings to persistent storage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Surgery settings saved successfully'),
        backgroundColor: _primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );

    // Simulate saving to backend
    _simulateSaveToBackend();
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Reset Settings', style: TextStyle(color: _primaryColor)),
          content: const Text(
            'Are you sure you want to reset all surgery settings to default values?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: _primaryColor)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performReset();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Settings reset to defaults'),
                    backgroundColor: _primaryColor,
                  ),
                );
              },
              child: Text('Reset', style: TextStyle(color: _secondaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _performReset() {
    setState(() {
      _enableSurgeryNotifications = true;
      _enablePreOpChecklist = true;
      _enablePostOpMonitoring = true;
      _enableSurgeryAuditLog = false;
      _autoGenerateSurgeryReports = true;
      _requireSurgeryConfirmation = true;

      _surgeryReminderTime = 30;
      _maxSurgeriesPerDay = 4;
      _defaultSurgeryDuration = 60;

      _defaultTheater = 'Operating Room 1';
      _anesthesiaDefault = 'General';
    });
  }

  void _viewEmergencyProtocol(String protocolName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$protocolName Protocol',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  child: Text(
                    _getProtocolDetails(protocolName),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getProtocolDetails(String protocolName) {
    switch (protocolName) {
      case 'Code Blue':
        return '1. Call Code Blue (5555)\n2. Start CPR immediately\n3. Bring crash cart and defibrillator\n4. Assign team roles\n5. Document all interventions\n6. Notify attending physician\n7. Prepare for transport to ICU';
      case 'Rapid Response':
        return '1. Assess patient ABCs\n2. Check vital signs\n3. Administer oxygen if needed\n4. Obtain IV access\n5. Draw labs\n6. Notify primary team\n7. Consider transfer to higher level of care';
      case 'Fire Emergency':
        return '1. RACE: Rescue, Alarm, Contain, Extinguish\n2. Turn off medical gases\n3. Remove flammable materials\n4. Use appropriate extinguisher\n5. Evacuate if necessary\n6. Account for all personnel';
      case 'Mass Casualty':
        return '1. Activate hospital emergency plan\n2. Triage patients using START system\n3. Prioritize treatment areas\n4. Mobilize all available staff\n5. Establish command center\n6. Coordinate with emergency services';
      default:
        return 'Protocol details not available.';
    }
  }

  void _simulateSaveToBackend() {
    // Simulate API call to save settings
    final settings = {
      'notifications': _enableSurgeryNotifications,
      'reminder_time': _surgeryReminderTime,
      'pre_op_checklist': _enablePreOpChecklist,
      'post_op_monitoring': _enablePostOpMonitoring,
      'audit_log': _enableSurgeryAuditLog,
      'auto_reports': _autoGenerateSurgeryReports,
      'confirmation_required': _requireSurgeryConfirmation,
      'max_surgeries': _maxSurgeriesPerDay,
      'default_duration': _defaultSurgeryDuration,
      'default_theater': _defaultTheater,
      'default_anesthesia': _anesthesiaDefault,
    };

    print('Saving settings to backend: $settings');
    // In a real app, you would make an API call here
  }
}
