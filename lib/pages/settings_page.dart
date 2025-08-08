import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: <Widget>[
          SwitchListTile(
            title: const Text('Modo oscuro'),
            value: settingsProvider.isDarkMode,
            onChanged: (bool value) {
              settingsProvider.toggleDarkMode(value);
            },
          ),
          ListTile(
            title: const Text('Idioma'),
            subtitle: Text(settingsProvider.language),
            onTap: () {
              _showLanguageDialog(context, settingsProvider);
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona el idioma'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<String>(
                title: const Text('Español'),
                value: 'es',
                groupValue: settingsProvider.language,
                onChanged: (String? value) {
                  if (value != null) {
                    settingsProvider.setLanguage(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Inglés'),
                value: 'en',
                groupValue: settingsProvider.language,
                onChanged: (String? value) {
                  if (value != null) {
                    settingsProvider.setLanguage(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
