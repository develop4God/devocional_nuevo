@Tags(['unit', 'models'])
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/models/discovery_card_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiscoveryCard Model Tests', () {
    test('should create natural_revelation card from JSON', () {
      final json = {
        'order': 1,
        'type': 'natural_revelation',
        'icon': '🔭',
        'title': 'El Testimonio de la Creación',
        'subtitle': 'Dios escribió Su plan en los cielos',
        'content': 'En astronomía, Venus es conocido como el Lucero del Alba',
        'revelation_key': 'Venus refleja la gloria del Sol',
      };

      final card = DiscoveryCard.fromJson(json);

      expect(card.order, equals(1));
      expect(card.type, equals('natural_revelation'));
      expect(card.icon, equals('🔭'));
      expect(card.title, equals('El Testimonio de la Creación'));
      expect(card.subtitle, equals('Dios escribió Su plan en los cielos'));
      expect(card.content, isNotNull);
      expect(card.revelationKey, equals('Venus refleja la gloria del Sol'));
    });

    test('should create historical_thread card with scripture connections', () {
      final json = {
        'order': 2,
        'type': 'historical_thread',
        'icon': '🏛️',
        'title': 'El Hilo Profético',
        'subtitle': 'De Balaam a los Magos',
        'content': 'La profecía de Balaam',
        'scripture_connections': [
          {'reference': 'Números 24:17', 'text': 'Saldrá ESTRELLA de Jacob'},
          {
            'reference': 'Mateo 2:2',
            'text': 'Hemos visto su estrella en el oriente',
          },
        ],
        'revelation_key': 'La profecía no se perdió',
      };

      final card = DiscoveryCard.fromJson(json);

      expect(card.order, equals(2));
      expect(card.type, equals('historical_thread'));
      expect(card.scriptureConnections, hasLength(2));
      expect(card.scriptureConnections![0].reference, equals('Números 24:17'));
      expect(
        card.scriptureConnections![1].text,
        equals('Hemos visto su estrella en el oriente'),
      );
    });

    test('should create greek_exegesis card with greek words', () {
      final json = {
        'order': 3,
        'type': 'greek_exegesis',
        'icon': '📖',
        'title': 'Los Tres Títulos de la Victoria',
        'greek_words': [
          {
            'word': 'Logos',
            'transliteration': 'Λόγος',
            'reference': 'Juan 1:1',
            'meaning': 'La Palabra',
            'revelation': 'Él es la expresión del pensamiento de Dios',
            'application': 'El Logos puede hablar orden sobre tu situación',
          },
          {
            'word': 'Eskēnōsen',
            'transliteration': 'ἐσκήνωσεν',
            'reference': 'Juan 1:14',
            'meaning': 'Puso Su tienda',
            'related_verb': 'Skēnē',
            'revelation': 'Se metió en una tienda de carne',
            'application': 'Conoce tus limitaciones',
          },
        ],
      };

      final card = DiscoveryCard.fromJson(json);

      expect(card.order, equals(3));
      expect(card.type, equals('greek_exegesis'));
      expect(card.greekWords, hasLength(2));
      expect(card.greekWords![0].word, equals('Logos'));
      expect(card.greekWords![0].transliteration, equals('Λόγος'));
      expect(card.greekWords![1].relatedVerb, equals('Skēnē'));
    });

    test('should create prophetic_promise card with scripture anchor', () {
      final json = {
        'order': 4,
        'type': 'prophetic_promise',
        'icon': '💎',
        'title': 'La Promesa para el Vencedor',
        'content': 'En Apocalipsis 2:26-28',
        'scripture_anchor': {
          'reference': 'Apocalipsis 22:16',
          'text': 'Yo soy la estrella resplandeciente de la mañana',
        },
        'identity_statement': 'No eres alguien que espera la luz',
        'revelation_key': 'La victoria no es algo que luchas por obtener',
      };

      final card = DiscoveryCard.fromJson(json);

      expect(card.order, equals(4));
      expect(card.type, equals('prophetic_promise'));
      expect(card.scriptureAnchor, isNotNull);
      expect(card.scriptureAnchor!.reference, equals('Apocalipsis 22:16'));
      expect(
        card.identityStatement,
        equals('No eres alguien que espera la luz'),
      );
    });

    test(
      'should create discovery_activation card with questions and prayer',
      () {
        final json = {
          'order': 5,
          'type': 'discovery_activation',
          'icon': '🧘',
          'title': 'Descubrimiento Personal',
          'discovery_questions': [
            {
              'category': 'Situación',
              'question': '¿En qué área de tu vida sientes oscuridad?',
            },
            {
              'category': 'Dirección',
              'question': '¿Qué sucede cuando dejas de mirar la Palabra?',
            },
          ],
          'prayer': {
            'title': 'Oración de Sellado',
            'content': 'Señor Jesús, mi Logos y mi Estrella de la Mañana...',
          },
        };

        final card = DiscoveryCard.fromJson(json);

        expect(card.order, equals(5));
        expect(card.type, equals('discovery_activation'));
        expect(card.discoveryQuestions, hasLength(2));
        expect(card.discoveryQuestions![0].category, equals('Situación'));
        expect(card.prayer, isNotNull);
        expect(card.prayer!.title, equals('Oración de Sellado'));
        expect(card.prayer!.content, contains('Señor Jesús'));
      },
    );

    test(
      'should parse scripture_references on any card type regardless of type-specific fields',
      () {
        final json = {
          'order': 2,
          'type': 'character_context',
          'title': 'El que no tiene nada que negociar',
          'content': 'Antes de hablar del joven rico...',
          'scripture_references': [
            {
              'reference': 'Mateo 19:14',
              'text': 'Y Jesús dijo: Dejad a los niños venir a mí, y no se lo '
                  'impidáis; porque de los tales es el reino de los cielos.',
            },
          ],
          'revelation_key': 'El Reino se ofrece a quien menos tiene',
        };

        final card = DiscoveryCard.fromJson(json);

        expect(card.scriptureReferences, hasLength(1));
        expect(card.scriptureReferences![0].reference, equals('Mateo 19:14'));
        expect(
          card.scriptureReferences![0].text,
          contains('Dejad a los niños'),
        );
      },
    );

    test('should serialize scripture_references to JSON correctly', () {
      final card = DiscoveryCard(
        order: 1,
        type: 'personal_application',
        title: 'Test Card',
        scriptureReferences: [
          VerseRef(reference: 'Mateo 19:14', text: 'Dejad a los niños...'),
        ],
      );

      final json = card.toJson();

      expect(json['scripture_references'], hasLength(1));
      expect(
        json['scripture_references'][0]['reference'],
        equals('Mateo 19:14'),
      );
    });

    test('should serialize card to JSON correctly', () {
      final card = DiscoveryCard(
        order: 1,
        type: 'natural_revelation',
        icon: '🌟',
        title: 'Test Card',
        subtitle: 'Test Subtitle',
        content: 'Test content',
        revelationKey: 'Test key',
      );

      final json = card.toJson();

      expect(json['order'], equals(1));
      expect(json['type'], equals('natural_revelation'));
      expect(json['icon'], equals('🌟'));
      expect(json['title'], equals('Test Card'));
      expect(json['subtitle'], equals('Test Subtitle'));
      expect(json['content'], equals('Test content'));
      expect(json['revelation_key'], equals('Test key'));
    });

    test('should handle missing optional fields gracefully', () {
      final json = {'order': 1, 'title': 'Minimal Card'};

      final card = DiscoveryCard.fromJson(json);

      expect(card.order, equals(1));
      expect(card.type, equals('natural_revelation')); // default
      expect(card.title, equals('Minimal Card'));
      expect(card.icon, isNull);
      expect(card.subtitle, isNull);
      expect(card.content, isNull);
      expect(card.scriptureConnections, isNull);
      expect(card.scriptureReferences, isNull);
      expect(card.greekWords, isNull);
    });
  });

  group('VerseRef Model Tests', () {
    test('should create VerseRef from JSON', () {
      final json = {
        'reference': '2 Pedro 1:19',
        'text': 'Tenemos también la palabra profética más segura',
      };

      final keyVerse = VerseRef.fromJson(json);

      expect(keyVerse.reference, equals('2 Pedro 1:19'));
      expect(keyVerse.text, contains('palabra profética'));
    });

    test('should serialize VerseRef to JSON', () {
      final keyVerse = VerseRef(
        reference: 'Juan 1:1',
        text: 'En el principio era el Verbo',
      );

      final json = keyVerse.toJson();

      expect(json['reference'], equals('Juan 1:1'));
      expect(json['text'], equals('En el principio era el Verbo'));
    });
  });

  group('Supporting Models Tests', () {
    test('VerseRef should serialize and deserialize', () {
      final json = {
        'reference': 'Génesis 1:1',
        'text': 'En el principio creó Dios',
      };

      final connection = VerseRef.fromJson(json);
      final serialized = connection.toJson();

      expect(connection.reference, equals('Génesis 1:1'));
      expect(serialized['reference'], equals('Génesis 1:1'));
      expect(serialized['text'], equals('En el principio creó Dios'));
    });

    test('GreekWord should serialize and deserialize', () {
      final json = {
        'word': 'Agape',
        'transliteration': 'Ἀγάπη',
        'reference': '1 Juan 4:8',
        'meaning': 'Amor divino',
        'revelation': 'Amor incondicional',
        'application': 'Ama como Dios ama',
      };

      final word = GreekWord.fromJson(json);
      final serialized = word.toJson();

      expect(word.word, equals('Agape'));
      expect(serialized['transliteration'], equals('Ἀγάπη'));
    });

    test('DiscoveryQuestion should serialize and deserialize', () {
      final json = {
        'category': 'Reflexión',
        'question': '¿Qué significa esto para ti?',
      };

      final question = DiscoveryQuestion.fromJson(json);
      final serialized = question.toJson();

      expect(question.category, equals('Reflexión'));
      expect(serialized['question'], equals('¿Qué significa esto para ti?'));
    });

    test('Prayer should handle optional title', () {
      final jsonWithTitle = {
        'title': 'Oración Final',
        'content': 'Señor, gracias...',
      };

      final prayerWithTitle = Prayer.fromJson(jsonWithTitle);
      expect(prayerWithTitle.title, equals('Oración Final'));

      final jsonWithoutTitle = {'content': 'Señor, gracias...'};

      final prayerWithoutTitle = Prayer.fromJson(jsonWithoutTitle);
      expect(prayerWithoutTitle.title, isNull);
      expect(prayerWithoutTitle.content, equals('Señor, gracias...'));
    });
  });
}
