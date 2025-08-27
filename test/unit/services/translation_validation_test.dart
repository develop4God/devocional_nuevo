import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Translation Validation Tests', () {
    late LocalizationService localizationService;

    setUp(() async {
      // Reset singleton instance for clean test state
      LocalizationService.resetInstance();

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Mock asset loading with comprehensive translation structure
      const Map<String, String> mockTranslations = {
        'i18n/es.json': '''
        {
          "app": {
            "title": "Devocionales",
            "loading": "Cargando...",
            "preparing": "Preparando tu espacio con Dios...",
            "cancel": "Cancelar",
            "delete": "Eliminar"
          },
          "prayer": {
            "enter_prayer_text_error": "Por favor ingresa el texto de la oración",
            "prayer_min_length_error": "La oración debe tener al menos 10 caracteres",
            "cancel": "Cancelar",
            "created": "Creada: {date}",
            "answered": "Respondida: {date}",
            "days_old_single": "({days} día)",
            "days_old_plural": "({days} días)"
          },
          "progress": {
            "title": "Progreso",
            "days": "días",
            "day": "día",
            "next_goal": "Siguiente meta: {goal} días",
            "goal_reached": "¡Meta alcanzada!",
            "devotionals_completed": "Devocionales completos",
            "favorites_saved": "Favoritos guardados",
            "achievements": "Logros",
            "last_activity": "Última Actividad: {date}",
            "no_activity": "Sin actividad"
          },
          "contact_page": {
            "title": "Contacto",
            "contact_us": "Contáctanos",
            "description": "Si tienes alguna pregunta, sugerencia o comentario, no dudes en ponerte en contacto con nosotros.",
            "contact_type_label": "Tipo de contacto",
            "message_label": "Tu mensaje",
            "message_hint": "Escribe tu mensaje aquí...",
            "other_contact_methods": "Otras formas de contacto"
          },
          "devotionals_page": {
            "added_to_favorites": "Devocional agregado a favoritos",
            "removed_from_favorites": "Devocional removido de favoritos"
          }
        }
        ''',
        'i18n/en.json': '''
        {
          "app": {
            "title": "Devotionals",
            "loading": "Loading...",
            "preparing": "Preparing your space with God...",
            "cancel": "Cancel",
            "delete": "Delete"
          },
          "prayer": {
            "enter_prayer_text_error": "Please enter the prayer text",
            "prayer_min_length_error": "Prayer must have at least 10 characters",
            "cancel": "Cancel",
            "created": "Created: {date}",
            "answered": "Answered: {date}",
            "days_old_single": "({days} day)",
            "days_old_plural": "({days} days)"
          },
          "progress": {
            "title": "Progress",
            "days": "days",
            "day": "day", 
            "next_goal": "Next goal: {goal} days",
            "goal_reached": "Goal reached!",
            "devotionals_completed": "Devotionals completed",
            "favorites_saved": "Favorites saved",
            "achievements": "Achievements",
            "last_activity": "Last Activity: {date}",
            "no_activity": "No activity"
          },
          "contact_page": {
            "title": "Contact",
            "contact_us": "Contact Us",
            "description": "If you have any questions, suggestions or comments, please don't hesitate to contact us.",
            "contact_type_label": "Contact type",
            "message_label": "Your message",
            "message_hint": "Write your message here...",
            "other_contact_methods": "Other contact methods"
          },
          "devotionals_page": {
            "added_to_favorites": "Devotional added to favorites",
            "removed_from_favorites": "Devotional removed from favorites"
          }
        }
        ''',
        'i18n/pt.json': '''
        {
          "app": {
            "title": "Devocionais",
            "loading": "Carregando...",
            "preparing": "Preparando seu espaço com Deus...",
            "cancel": "Cancelar",
            "delete": "Excluir"
          },
          "prayer": {
            "enter_prayer_text_error": "Por favor, insira o texto da oração",
            "prayer_min_length_error": "A oração deve ter pelo menos 10 caracteres",
            "cancel": "Cancelar",
            "created": "Criada: {date}",
            "answered": "Respondida: {date}",
            "days_old_single": "({days} dia)",
            "days_old_plural": "({days} dias)"
          },
          "progress": {
            "title": "Progresso",
            "days": "dias",
            "day": "dia",
            "next_goal": "Próxima meta: {goal} dias",
            "goal_reached": "Meta alcançada!",
            "devotionals_completed": "Devocionais completos",
            "favorites_saved": "Favoritos salvos",
            "achievements": "Conquistas",
            "last_activity": "Última Atividade: {date}",
            "no_activity": "Sem atividade"
          },
          "contact_page": {
            "title": "Contato",
            "contact_us": "Entre em Contato",
            "description": "Se você tiver alguma pergunta, sugestão ou comentário, não hesite em entrar em contato conosco.",
            "contact_type_label": "Tipo de contato",
            "message_label": "Sua mensagem",
            "message_hint": "Escreva sua mensagem aqui...",
            "other_contact_methods": "Outros métodos de contato"
          },
          "devotionals_page": {
            "added_to_favorites": "Devocional adicionado aos favoritos",
            "removed_from_favorites": "Devocional removido dos favoritos"
          }
        }
        ''',
        'i18n/fr.json': '''
        {
          "app": {
            "title": "Dévotionnels",
            "loading": "Chargement...",
            "preparing": "Préparation de votre espace avec Dieu...",
            "cancel": "Annuler",
            "delete": "Supprimer"
          },
          "prayer": {
            "enter_prayer_text_error": "Veuillez saisir le texte de la prière",
            "prayer_min_length_error": "La prière doit contenir au moins 10 caractères",
            "cancel": "Annuler",
            "created": "Créée: {date}",
            "answered": "Répondue: {date}",
            "days_old_single": "({days} jour)",
            "days_old_plural": "({days} jours)"
          },
          "progress": {
            "title": "Progrès",
            "days": "jours",
            "day": "jour",
            "next_goal": "Prochain objectif: {goal} jours",
            "goal_reached": "Objectif atteint!",
            "devotionals_completed": "Dévotionnels complétés",
            "favorites_saved": "Favoris sauvegardés",
            "achievements": "Réalisations",
            "last_activity": "Dernière Activité: {date}",
            "no_activity": "Aucune activité"
          },
          "contact_page": {
            "title": "Contact",
            "contact_us": "Contactez-nous",
            "description": "Si vous avez des questions, suggestions ou commentaires, n'hésitez pas à nous contacter.",
            "contact_type_label": "Type de contact",
            "message_label": "Votre message",
            "message_hint": "Écrivez votre message ici...",
            "other_contact_methods": "Autres méthodes de contact"
          },
          "devotionals_page": {
            "added_to_favorites": "Dévotionnel ajouté aux favoris",
            "removed_from_favorites": "Dévotionnel retiré des favoris"
          }
        }
        '''
      };

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            final String key = methodCall.arguments as String;
            return mockTranslations[key];
          }
          return null;
        },
      );

      // Get fresh instance and initialize
      localizationService = LocalizationService.instance;
      await localizationService.initialize();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        null,
      );
    });

    group('App-wide Translation Keys', () {
      test('should translate basic app keys across all languages', () async {
        // Test Spanish
        await localizationService.changeLocale(const Locale('es'));
        expect(localizationService.translate('app.title'), equals('Devocionales'));
        expect(localizationService.translate('app.loading'), equals('Cargando...'));
        
        // Test English
        await localizationService.changeLocale(const Locale('en'));
        expect(localizationService.translate('app.title'), equals('Devotionals'));
        expect(localizationService.translate('app.loading'), equals('Loading...'));
        
        // Test Portuguese
        await localizationService.changeLocale(const Locale('pt'));
        expect(localizationService.translate('app.title'), equals('Devocionais'));
        expect(localizationService.translate('app.loading'), equals('Carregando...'));
        
        // Test French
        await localizationService.changeLocale(const Locale('fr'));
        expect(localizationService.translate('app.title'), equals('Dévotionnels'));
        expect(localizationService.translate('app.loading'), equals('Chargement...'));
      });
    });

    group('Prayer Module Translation Validation', () {
      test('should translate prayer validation errors correctly', () async {
        // Test Spanish
        await localizationService.changeLocale(const Locale('es'));
        expect(localizationService.translate('prayer.enter_prayer_text_error'), 
               equals('Por favor ingresa el texto de la oración'));
        expect(localizationService.translate('prayer.prayer_min_length_error'), 
               equals('La oración debe tener al menos 10 caracteres'));
        
        // Test English
        await localizationService.changeLocale(const Locale('en'));
        expect(localizationService.translate('prayer.enter_prayer_text_error'), 
               equals('Please enter the prayer text'));
        expect(localizationService.translate('prayer.prayer_min_length_error'), 
               equals('Prayer must have at least 10 characters'));
        
        // Test Portuguese
        await localizationService.changeLocale(const Locale('pt'));
        expect(localizationService.translate('prayer.enter_prayer_text_error'), 
               equals('Por favor, insira o texto da oração'));
        expect(localizationService.translate('prayer.prayer_min_length_error'), 
               equals('A oração deve ter pelo menos 10 caracteres'));
        
        // Test French
        await localizationService.changeLocale(const Locale('fr'));
        expect(localizationService.translate('prayer.enter_prayer_text_error'), 
               equals('Veuillez saisir le texte de la prière'));
        expect(localizationService.translate('prayer.prayer_min_length_error'), 
               equals('La prière doit contenir au moins 10 caractères'));
      });

      test('should handle parameter interpolation in prayer timestamps', () async {
        await localizationService.changeLocale(const Locale('es'));
        expect(localizationService.translate('prayer.created', {'date': '25/12/2024'}), 
               equals('Creada: 25/12/2024'));
        expect(localizationService.translate('prayer.days_old_plural', {'days': '5'}), 
               equals('(5 días)'));
        
        await localizationService.changeLocale(const Locale('en'));
        expect(localizationService.translate('prayer.created', {'date': '25/12/2024'}), 
               equals('Created: 25/12/2024'));
        expect(localizationService.translate('prayer.days_old_single', {'days': '1'}), 
               equals('(1 day)'));
      });
    });

    group('Progress Module Translation Validation', () {
      test('should translate progress statistics correctly', () async {
        // Test Spanish
        await localizationService.changeLocale(const Locale('es'));
        expect(localizationService.translate('progress.title'), equals('Progreso'));
        expect(localizationService.translate('progress.devotionals_completed'), 
               equals('Devocionales completos'));
        expect(localizationService.translate('progress.achievements'), equals('Logros'));
        
        // Test English
        await localizationService.changeLocale(const Locale('en'));
        expect(localizationService.translate('progress.title'), equals('Progress'));
        expect(localizationService.translate('progress.devotionals_completed'), 
               equals('Devotionals completed'));
        expect(localizationService.translate('progress.achievements'), equals('Achievements'));
        
        // Test Portuguese
        await localizationService.changeLocale(const Locale('pt'));
        expect(localizationService.translate('progress.title'), equals('Progresso'));
        expect(localizationService.translate('progress.devotionals_completed'), 
               equals('Devocionais completos'));
        expect(localizationService.translate('progress.achievements'), equals('Conquistas'));
        
        // Test French
        await localizationService.changeLocale(const Locale('fr'));
        expect(localizationService.translate('progress.title'), equals('Progrès'));
        expect(localizationService.translate('progress.devotionals_completed'), 
               equals('Dévotionnels complétés'));
        expect(localizationService.translate('progress.achievements'), equals('Réalisations'));
      });

      test('should handle goal progress with parameters', () async {
        await localizationService.changeLocale(const Locale('es'));
        expect(localizationService.translate('progress.next_goal', {'goal': '7'}), 
               equals('Siguiente meta: 7 días'));
        expect(localizationService.translate('progress.goal_reached'), 
               equals('¡Meta alcanzada!'));
        
        await localizationService.changeLocale(const Locale('en'));
        expect(localizationService.translate('progress.next_goal', {'goal': '7'}), 
               equals('Next goal: 7 days'));
        expect(localizationService.translate('progress.goal_reached'), 
               equals('Goal reached!'));
      });
    });

    group('Contact Module Translation Validation', () {
      test('should translate contact form elements correctly', () async {
        // Test Spanish
        await localizationService.changeLocale(const Locale('es'));
        expect(localizationService.translate('contact_page.title'), equals('Contacto'));
        expect(localizationService.translate('contact_page.contact_us'), equals('Contáctanos'));
        expect(localizationService.translate('contact_page.contact_type_label'), 
               equals('Tipo de contacto'));
        
        // Test English
        await localizationService.changeLocale(const Locale('en'));
        expect(localizationService.translate('contact_page.title'), equals('Contact'));
        expect(localizationService.translate('contact_page.contact_us'), equals('Contact Us'));
        expect(localizationService.translate('contact_page.contact_type_label'), 
               equals('Contact type'));
        
        // Test Portuguese
        await localizationService.changeLocale(const Locale('pt'));
        expect(localizationService.translate('contact_page.title'), equals('Contato'));
        expect(localizationService.translate('contact_page.contact_us'), equals('Entre em Contato'));
        expect(localizationService.translate('contact_page.contact_type_label'), 
               equals('Tipo de contato'));
        
        // Test French
        await localizationService.changeLocale(const Locale('fr'));
        expect(localizationService.translate('contact_page.title'), equals('Contact'));
        expect(localizationService.translate('contact_page.contact_us'), equals('Contactez-nous'));
        expect(localizationService.translate('contact_page.contact_type_label'), 
               equals('Type de contact'));
      });
    });

    group('Devotional Actions Translation Validation', () {
      test('should translate devotional action confirmations correctly', () async {
        // Test Spanish
        await localizationService.changeLocale(const Locale('es'));
        expect(localizationService.translate('devotionals_page.added_to_favorites'), 
               equals('Devocional agregado a favoritos'));
        expect(localizationService.translate('devotionals_page.removed_from_favorites'), 
               equals('Devocional removido de favoritos'));
        
        // Test English
        await localizationService.changeLocale(const Locale('en'));
        expect(localizationService.translate('devotionals_page.added_to_favorites'), 
               equals('Devotional added to favorites'));
        expect(localizationService.translate('devotionals_page.removed_from_favorites'), 
               equals('Devotional removed from favorites'));
        
        // Test Portuguese
        await localizationService.changeLocale(const Locale('pt'));
        expect(localizationService.translate('devotionals_page.added_to_favorites'), 
               equals('Devocional adicionado aos favoritos'));
        expect(localizationService.translate('devotionals_page.removed_from_favorites'), 
               equals('Devocional removido dos favoritos'));
        
        // Test French
        await localizationService.changeLocale(const Locale('fr'));
        expect(localizationService.translate('devotionals_page.added_to_favorites'), 
               equals('Dévotionnel ajouté aux favoris'));
        expect(localizationService.translate('devotionals_page.removed_from_favorites'), 
               equals('Dévotionnel retiré des favoris'));
      });
    });

    group('Translation Coverage and Fallback', () {
      test('should return key when translation not found', () async {
        await localizationService.changeLocale(const Locale('es'));
        expect(localizationService.translate('non.existent.key'), 
               equals('non.existent.key'));
      });

      test('should handle empty parameters gracefully', () async {
        await localizationService.changeLocale(const Locale('es'));
        expect(localizationService.translate('prayer.created', {}), 
               equals('Creada: {date}'));
      });

      test('should validate all critical UI translation keys exist', () async {
        await localizationService.changeLocale(const Locale('es'));
        
        // Critical app-wide keys
        expect(localizationService.translate('app.title'), isNot(equals('app.title')));
        expect(localizationService.translate('app.cancel'), isNot(equals('app.cancel')));
        expect(localizationService.translate('app.delete'), isNot(equals('app.delete')));
        
        // Prayer management keys
        expect(localizationService.translate('prayer.cancel'), isNot(equals('prayer.cancel')));
        expect(localizationService.translate('prayer.enter_prayer_text_error'), 
               isNot(equals('prayer.enter_prayer_text_error')));
        
        // Progress tracking keys
        expect(localizationService.translate('progress.title'), isNot(equals('progress.title')));
        expect(localizationService.translate('progress.achievements'), 
               isNot(equals('progress.achievements')));
        
        // Contact form keys
        expect(localizationService.translate('contact_page.title'), 
               isNot(equals('contact_page.title')));
        expect(localizationService.translate('contact_page.contact_us'), 
               isNot(equals('contact_page.contact_us')));
      });
    });
  });
}