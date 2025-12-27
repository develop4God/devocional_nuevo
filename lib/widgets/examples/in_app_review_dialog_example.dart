import 'package:flutter/material.dart';
import '../app_gradient_dialog.dart';

/// Example widget showing the new In-App Review dialog design
/// This is for documentation and visual reference purposes
class InAppReviewDialogExample extends StatelessWidget {
  const InAppReviewDialogExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In-App Review Dialog Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showExampleDialog(context),
          child: const Text('Show Review Dialog Example'),
        ),
      ),
    );
  }

  void _showExampleDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AppGradientDialog(
          maxWidth: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with gradient background
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(100),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.star_rounded,
                  size: 48,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Gracias por tu constancia 🙏',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                'Si Dios te está hablando a través de estos devocionales, compartir tu testimonio podría ser justo lo que alguien más necesita escuchar para acercarse a Él.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(200),
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),

              // Primary action button - "Share" with gradient
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('In-App Review would be triggered here'),
                        ),
                      );
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.share_rounded,
                            color: colorScheme.onPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sí, quiero compartir',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary button - "Already rated"
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User marked as already rated'),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface.withAlpha(180),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ya la califiqué',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),

              // Tertiary button - "Not now"
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Remind later set for 30 days'),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface.withAlpha(150),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ahora no',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
