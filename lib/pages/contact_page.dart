// lib/pages/contact_page.dart
// Esta página permite al usuario contactar con los desarrolladores de la aplicación.

import 'dart:developer' as developer;

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  String? _selectedContactOption;
  final TextEditingController _messageController = TextEditingController();

  // Mover las opciones a una variable de instancia para evitar recrearlas
  late final List<String> _contactOptions;

  @override
  void initState() {
    super.initState();
    // Inicializar las opciones una sola vez
    _contactOptions = [
      'contact.bugs'.tr(),
      'contact.feedback'.tr(),
      'contact.improvements'.tr(),
      'contact.other'.tr()
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendContactEmail() async {
    // Validación con mejor UX
    if (_selectedContactOption == null) {
      _showValidationError('contact.select_type_error'.tr());
      return;
    }

    final String message = _messageController.text.trim();
    if (message.isEmpty) {
      _showValidationError('contact.enter_message_error'.tr());
      return;
    }

    // Construir el enlace mailto con los datos del formulario de opciones
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'develop4god@gmail.com',
      query: 'subject=${Uri.encodeComponent('contact.email_subject'.tr({
            'type': _selectedContactOption!
          }))}&body=${Uri.encodeComponent(message)}',
    );

    developer.log('Intentando abrir cliente de correo: $emailUri',
        name: 'EmailLaunch');

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (mounted) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('contact.opening_email_client'.tr()),
              backgroundColor: Colors.green,
            ),
          );
          // Limpiar el formulario
          setState(() {
            _selectedContactOption = null;
            _messageController.clear();
          });
        }
      } else {
        _showErrorSnackBar(
            'No se pudo abrir el cliente de correo. Por favor, envía un correo manualmente a develop4god@gmail.com');
      }
    } catch (e) {
      developer.log('Error al intentar abrir cliente de correo: $e',
          error: e, name: 'EmailLaunch');
      _showErrorSnackBar(
          'Error al abrir el cliente de correo: ${e.toString()}');
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'contact_page.title'.tr(),
          style:
              TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la página
            Text(
              'contact_page.contact_us'.tr(),
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Descripción
            Text(
              'contact_page.description'.tr(),
              style:
                  textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 30),

            // SOLUCIÓN: Cambio a Container con DropdownButton para eliminar inconsistencias
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _selectedContactOption,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.topic_outlined, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'contact.select_option'.tr(),
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                // Remover la línea por defecto
                items: _contactOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.topic_outlined,
                              color: colorScheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(option)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedContactOption = newValue;
                  });
                },
                // Estilizado personalizado
                selectedItemBuilder: (BuildContext context) {
                  return _contactOptions.map((String option) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.topic_outlined,
                              color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            const SizedBox(height: 20),

            // Campo de texto para el mensaje (sin cambios)
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'contact_page.message_label'.tr(),
                hintText: 'contact_page.message_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.message, color: colorScheme.primary),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),

            // Botón de enviar
            Center(
              child: ElevatedButton.icon(
                onPressed: _sendContactEmail,
                icon: Icon(Icons.send, color: colorScheme.onPrimary),
                label: Text('contact.open_email'.tr(),
                    style: TextStyle(color: colorScheme.onPrimary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            // Otras formas de contacto (sin cambios)
            Text(
              'contact_page.other_contact_methods'.tr(),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 15),

            // Email directo
            ListTile(
              leading: Icon(Icons.email, color: colorScheme.primary),
              title: Text('develop4God@gmail.com',
                  style: TextStyle(color: colorScheme.onSurface)),
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'develop4god@gmail.com',
                );
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                } else {
                  _showErrorSnackBar('No se pudo abrir el cliente de correo');
                }
              },
            ),

            // Sitio web
            ListTile(
              leading: Icon(Icons.language, color: colorScheme.primary),
              title: Text('contact.visit_website'.tr(),
                  style: TextStyle(color: colorScheme.onSurface)),
              onTap: () async {
                final Uri webUri = Uri.parse('https://develop4god.github.io/');
                if (await canLaunchUrl(webUri)) {
                  await launchUrl(webUri, mode: LaunchMode.externalApplication);
                } else {
                  _showErrorSnackBar('No se pudo abrir el navegador');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
