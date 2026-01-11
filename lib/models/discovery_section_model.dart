// lib/models/discovery_section_model.dart

/// Modelo de datos para una sección de estudio Discovery.
///
/// Las secciones pueden ser de tipo natural (observación del mundo natural)
/// o de tipo scripture (estudio bíblico con pasajes).
class DiscoverySection {
  final String tipo;
  final String? icono;
  final String? titulo;
  final String? contenido;
  final List<ScripturePassage>? pasajes;

  DiscoverySection({
    required this.tipo,
    this.icono,
    this.titulo,
    this.contenido,
    this.pasajes,
  });

  /// Constructor factory para crear una instancia desde JSON.
  factory DiscoverySection.fromJson(Map<String, dynamic> json) {
    return DiscoverySection(
      tipo: json['tipo'] as String? ?? '',
      icono: json['icono'] as String?,
      titulo: json['titulo'] as String?,
      contenido: json['contenido'] as String?,
      pasajes: (json['pasajes'] as List<dynamic>?)
          ?.map(
              (item) => ScripturePassage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Método toJson para serializar a JSON.
  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'icono': icono,
      'titulo': titulo,
      'contenido': contenido,
      'pasajes': pasajes?.map((p) => p.toJson()).toList(),
    };
  }

  /// Indica si la sección es de tipo natural.
  bool get isNatural => tipo == 'natural';

  /// Indica si la sección es de tipo scripture.
  bool get isScripture => tipo == 'scripture';
}

/// Modelo de datos para un pasaje bíblico dentro de una sección.
class ScripturePassage {
  final String referencia;
  final String texto;
  final String? aplicacion;

  ScripturePassage({
    required this.referencia,
    required this.texto,
    this.aplicacion,
  });

  /// Constructor factory para crear una instancia desde JSON.
  factory ScripturePassage.fromJson(Map<String, dynamic> json) {
    return ScripturePassage(
      referencia: json['referencia'] as String? ?? '',
      texto: json['texto'] as String? ?? '',
      aplicacion: json['aplicacion'] as String?,
    );
  }

  /// Método toJson para serializar a JSON.
  Map<String, dynamic> toJson() {
    return {
      'referencia': referencia,
      'texto': texto,
      'aplicacion': aplicacion,
    };
  }
}
