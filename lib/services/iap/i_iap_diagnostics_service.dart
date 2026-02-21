// lib/services/iap/i_iap_diagnostics_service.dart
//
// Interface for IAP diagnostics printing.
// Extracted so that [IapService] does not depend on the concrete
// [IapDiagnosticsService] class (Dependency Inversion Principle).

/// Contract for printing IAP diagnostic information to the debug console.
abstract class IIapDiagnosticsService {
  /// Prints a formatted diagnostic report.
  void printDiagnostics();
}
