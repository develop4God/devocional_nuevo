// lib/models/discovery_card_model.dart

/// Modelo de datos para una tarjeta de estudio Discovery.
///
/// Las tarjetas pueden ser de varios tipos:
/// - natural_revelation: Observación del mundo natural
/// - historical_thread: Conexiones históricas y proféticas
/// - greek_exegesis: Análisis de palabras griegas
/// - prophetic_promise: Promesas proféticas
/// - discovery_activation: Preguntas de descubrimiento y oración
class DiscoveryCard {
  final int order;
  final String type;
  final String? icon;
  final String title;
  final String? subtitle;
  final String? content;
  final String? revelationKey;

  // For type: historical_thread
  final List<ScriptureConnection>? scriptureConnections;

  // For type: greek_exegesis
  final List<GreekWord>? greekWords;

  // For type: prophetic_promise
  final ScriptureAnchor? scriptureAnchor;
  final String? identityStatement;

  // For type: discovery_activation
  final List<DiscoveryQuestion>? discoveryQuestions;
  final Prayer? prayer;

  DiscoveryCard({
    required this.order,
    required this.type,
    this.icon,
    required this.title,
    this.subtitle,
    this.content,
    this.revelationKey,
    this.scriptureConnections,
    this.greekWords,
    this.scriptureAnchor,
    this.identityStatement,
    this.discoveryQuestions,
    this.prayer,
  });

  /// Constructor factory para crear una instancia desde JSON.
  factory DiscoveryCard.fromJson(Map<String, dynamic> json) {
    return DiscoveryCard(
      order: json['order'] as int? ?? 0,
      type: json['type'] as String? ?? 'natural_revelation',
      icon: json['icon'] as String?,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      content: json['content'] as String?,
      revelationKey: json['revelation_key'] as String?,
      scriptureConnections: (json['scripture_connections'] as List<dynamic>?)
          ?.map(
            (e) => ScriptureConnection.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      greekWords: (json['greek_words'] as List<dynamic>?)
          ?.map(
            (e) => GreekWord.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      scriptureAnchor: json['scripture_anchor'] != null
          ? ScriptureAnchor.fromJson(
              json['scripture_anchor'] as Map<String, dynamic>,
            )
          : null,
      identityStatement: json['identity_statement'] as String?,
      discoveryQuestions: (json['discovery_questions'] as List<dynamic>?)
          ?.map(
            (e) => DiscoveryQuestion.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      prayer: json['prayer'] != null
          ? Prayer.fromJson(json['prayer'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Metodo toJson para serializar a JSON.
  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'type': type,
      'icon': icon,
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'revelation_key': revelationKey,
      'scripture_connections':
          scriptureConnections?.map((e) => e.toJson()).toList(),
      'greek_words': greekWords?.map((e) => e.toJson()).toList(),
      'scripture_anchor': scriptureAnchor?.toJson(),
      'identity_statement': identityStatement,
      'discovery_questions':
          discoveryQuestions?.map((e) => e.toJson()).toList(),
      'prayer': prayer?.toJson(),
    };
  }
}

/// Modelo de datos para una conexión bíblica.
class ScriptureConnection {
  final String reference;
  final String text;

  ScriptureConnection({required this.reference, required this.text});

  factory ScriptureConnection.fromJson(Map<String, dynamic> json) {
    return ScriptureConnection(
      reference: json['reference'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'text': text,
    };
  }
}

/// Modelo de datos para una palabra griega.
class GreekWord {
  final String word;
  final String? transliteration;
  final String reference;
  final String meaning;
  final String? relatedVerb;
  final String revelation;
  final String application;

  GreekWord({
    required this.word,
    this.transliteration,
    required this.reference,
    required this.meaning,
    this.relatedVerb,
    required this.revelation,
    required this.application,
  });

  factory GreekWord.fromJson(Map<String, dynamic> json) {
    return GreekWord(
      word: json['word'] as String? ?? '',
      transliteration: json['transliteration'] as String?,
      reference: json['reference'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      relatedVerb: json['related_verb'] as String?,
      revelation: json['revelation'] as String? ?? '',
      application: json['application'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'transliteration': transliteration,
      'reference': reference,
      'meaning': meaning,
      'related_verb': relatedVerb,
      'revelation': revelation,
      'application': application,
    };
  }
}

/// Modelo de datos para un ancla bíblica.
class ScriptureAnchor {
  final String reference;
  final String text;

  ScriptureAnchor({required this.reference, required this.text});

  factory ScriptureAnchor.fromJson(Map<String, dynamic> json) {
    return ScriptureAnchor(
      reference: json['reference'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'text': text,
    };
  }
}

/// Modelo de datos para una pregunta de descubrimiento.
class DiscoveryQuestion {
  final String category;
  final String question;

  DiscoveryQuestion({required this.category, required this.question});

  factory DiscoveryQuestion.fromJson(Map<String, dynamic> json) {
    return DiscoveryQuestion(
      category: json['category'] as String? ?? '',
      question: json['question'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'question': question,
    };
  }
}

/// Modelo de datos para una oración.
class Prayer {
  final String? title;
  final String content;

  Prayer({this.title, required this.content});

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}

/// Modelo de datos para el versículo clave.
class KeyVerse {
  final String reference;
  final String text;

  KeyVerse({required this.reference, required this.text});

  factory KeyVerse.fromJson(Map<String, dynamic> json) {
    return KeyVerse(
      reference: json['reference'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'text': text,
    };
  }
}
