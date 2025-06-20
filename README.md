Descripción del Flujo y Componentes:

main.dart: Es el punto de entrada de la aplicación. Configura el tema, la localización y el DevocionalProvider global utilizando ChangeNotifierProvider, y lanza la SplashScreen.

SplashScreen: La primera pantalla visible. Muestra una animación mientras la aplicación se inicializa. Después de un tiempo, navega a AppInitializer.

AppInitializer: Un widget intermedio crucial. Su initState llama a _initializeAppData que, a su vez, invoca devocionalProvider.initializeData(). Una vez que los datos están cargados, navega a la DevocionalesPage.

DevocionalProvider: El corazón de la gestión de datos de la aplicación (usando el patrón Provider). Es un ChangeNotifier que:

Carga devocionales desde una API Remota (JSON de GitHub) usando http.

Detecta y gestiona el idioma y la versión seleccionados por el usuario, guardándolos en SharedPreferences.

Filtra los devocionales cargados según la versión seleccionada.

Maneja la lógica de "favoritos" (añadir/quitar) y persiste esta lista en SharedPreferences.

Controla la visibilidad de un "diálogo de invitación" (Oración de Fe), también guardando la preferencia en SharedPreferences.

Notifica a sus consumidores (widgets de UI) sobre cambios en los datos.

DevocionalModel: Define la estructura de datos para un devocional (Devocional) y sus subcomponentes (ParaMeditar). Incluye métodos fromJson y toJson para la serialización y deserialización de datos, facilitando su almacenamiento y recuperación.

constants.dart: Contiene la lógica para construir la URL de la API remota de devocionales (basada en el año) y otras constantes como las claves para SharedPreferences.

DevocionalesPage: La pantalla principal donde los usuarios ven el contenido del devocional del día.

Consume los datos del DevocionalProvider.

Permite la navegación entre devocionales (anterior/siguiente).

Ofrece opciones para marcar como favorito, compartir (como texto o imagen - captura de pantalla) y navegar a la SettingsPage.

Muestra un diálogo de "Oración de Fe" si no se ha deshabilitado.

FavoritesPage: Muestra una lista de todos los devocionales que el usuario ha marcado como favoritos.

También consume el DevocionalProvider para obtener la lista de favoritos.

Permite "quitar de favoritos".

Al tocar un favorito, navega de vuelta a la DevocionalesPage mostrando ese devocional específico.

SettingsPage: La pantalla de ajustes.

Permite cambiar el idioma (actualmente solo español, pero preparado para más).

Incluye un botón para donaciones (enlace a PayPal).

Permite navegar a la FavoritesPage directamente.

HomePage: (Contenedor de Pestañas Opcional): Aunque existe en el código, no está directamente enlazada en el flujo de inicio actual (main.dart -> SplashScreen -> AppInitializer -> DevocionalesPage). Su propósito es servir como un contenedor con una BottomNavigationBar para navegar entre DevocionalesPage, FavoritesPage y SettingsPage como pestañas. Esto podría ser una evolución futura de la navegación principal.

README para la Aplicación Flutter de Devocionales
Aplicación de Devocionales Bíblicos
🌐 Selecciona tu Idioma / Select your Language
Español (ES)

English (EN)

Español (ES)
Esta es una aplicación móvil Flutter diseñada para ofrecer devocionales bíblicos diarios. La aplicación carga contenido dinámicamente desde una API remota (un repositorio GitHub que sirve archivos JSON) y permite a los usuarios leer, navegar, marcar devocionales como favoritos, compartir contenido y gestionar algunas preferencias básicas.

🚀 Características Principales
Devocionales Diarios: Acceso a un devocional diferente cada día.

Soporte Multi-Versión: Los devocionales pueden estar disponibles en diferentes versiones bíblicas (ej. RVR1960).

Favoritos: Guarda tus devocionales preferidos para acceder a ellos fácilmente en el futuro.

Compartir Contenido: Comparte devocionales como texto o como imagen (captura de pantalla) a través de otras aplicaciones.

Oración de Fe: Incluye una oración de fe que puede ser mostrada o deshabilitada.

Personalización de Idioma: Preparada para soportar múltiples idiomas (actualmente configurada para español).

Interfaz Intuitiva: Navegación sencilla entre devocionales y secciones de la aplicación.

🏗️ Arquitectura y Componentes Clave
La aplicación está construida utilizando el framework Flutter y sigue principios de arquitectura modular y gestión de estado con Provider.

Diagrama de Arquitectura de la Aplicación
graph TD
    subgraph App de Devocionales
        A[main.dart<br>(Punto de Entrada)] --> B(SplashScreen<br>(Animación Inicial))
        B --> C(AppInitializer<br>(Carga y Setup Inicial))
        C --> D(DevocionalesPage<br>(Contenido Principal))

        D -- Navega a --> E(SettingsPage<br>(Opciones/Ajustes))
        D -- Toggle/Gestiona --> F(DevocionalProvider<br>(Gestión de Estado/Datos))

        E -- Navega a --> G(FavoritesPage<br>(Devocionales Favoritos))
        G -- Navega de vuelta a --> D

        F -- Obtiene Datos --> H(API Remota<br>(GitHub JSON))
        F -- Guarda/Carga Datos --> I(SharedPreferences<br>(Datos Locales))
        F -- Usa Estructura --> J(DevocionalModel<br>(Modelos de Datos))

        K(HomePage<br>(Contenedor de Pestañas Opcional))
    end

    subgraph Componentes Clave
        J -- Define Estructura --> Devocional{Devocional y ParaMeditar}
        H -- URL de API --> L(constants.dart<br>(Constantes/URLs))
    end

    style D fill:#f9f,stroke:#333,stroke-width:2px
    style G fill:#f9f,stroke:#333,stroke-width:2px
    style E fill:#f9f,stroke:#333,stroke-width:2px
    style F fill:#ADD8E6,stroke:#333,stroke-width:2px
    style J fill:#FFD700,stroke:#333,stroke-width:2px
    style K fill:#D3D3D3,stroke:#333,stroke-width:1px

Descripción de Archivos Clave (lib folder)
main.dart:

Propósito: Punto de entrada de la aplicación.

Funcionalidad: Inicializa Flutter, configura la internacionalización de fechas, envuelve la aplicación en ChangeNotifierProvider para DevocionalProvider, define el tema visual global y establece SplashScreen como la pantalla inicial.

splash_screen.dart:

Propósito: Pantalla de carga inicial.

Funcionalidad: Muestra una animación de desvanecimiento con una imagen de fondo y un mensaje. Después de un breve retraso, navega a AppInitializer para comenzar la carga real de datos.

app_initializer.dart:

Propósito: Encargado de la inicialización asíncrona de los datos de la aplicación.

Funcionalidad: Utiliza Provider para acceder al DevocionalProvider y llama a su método initializeData(). Una vez que los datos están cargados (o se produce un error), navega a la DevocionalesPage.

providers/devocional_provider.dart:

Propósito: Gestiona el estado y los datos de los devocionales a lo largo de la aplicación.

Funcionalidad:

Carga todos los devocionales de un año específico desde un JSON remoto (servido por GitHub).

Filtra los devocionales por la versión bíblica seleccionada (ej. RVR1960).

Maneja la lista de devocionales favoritos del usuario, guardándolos y cargándolos usando shared_preferences.

Gestiona la preferencia para mostrar o no el diálogo de la "Oración de Fe".

Notifica a los widgets que escuchan sobre cualquier cambio de estado (ej. datos cargados, favorito añadido).

models/devocional_model.dart:

Propósito: Define las estructuras de datos (Devocional y ParaMeditar) utilizadas para representar el contenido de los devocionales.

Funcionalidad: Incluye constructores factory (fromJson) para parsear objetos JSON en instancias de Dart, y métodos toJson para serializar instancias de Dart a objetos JSON (útil para guardar favoritos).

utils/constants.dart:

Propósito: Almacena constantes y utilidades globales.

Funcionalidad: Contiene la función getDevocionalesApiUrl para construir la URL del archivo JSON de devocionales en GitHub, basándose en el año. También define claves para SharedPreferences.

pages/devocionales_page.dart:

Propósito: Muestra el devocional actual con opciones de interacción.

Funcionalidad:

Muestra el versículo, reflexión, "para meditar" y la oración del devocional actual.

Permite navegar entre devocionales anteriores y siguientes.

Integra botones para marcar/desmarcar como favorito, compartir el contenido como texto o como una captura de pantalla, y acceder a la página de ajustes.

Muestra el diálogo de la "Oración de Fe" bajo ciertas condiciones.

pages/favorites_page.dart:

Propósito: Muestra la lista de devocionales marcados como favoritos.

Funcionalidad: Presenta una lista desplazable de tarjetas de devocionales favoritos. Al hacer clic en una tarjeta, navega de vuelta a la DevocionalesPage para mostrar ese devocional específico. Permite eliminar devocionales de la lista de favoritos.

pages/home_page.dart:

Propósito: (Potencial) Servir como contenedor principal con navegación por pestañas.

Funcionalidad: Define un BottomNavigationBar para alternar entre DevocionalesPage, FavoritesPage y una SettingsPage (placeholder). Nota: En el flujo actual de la aplicación, esta HomePage no es directamente utilizada como la pantalla principal después de la inicialización, pero representa una estructura de navegación común en aplicaciones Flutter.

pages/settings_page.dart:

Propósito: Ofrece opciones de configuración y enlaces externos.

Funcionalidad: Permite al usuario cambiar el idioma de la aplicación (actualmente solo español). Incluye un botón para hacer donaciones (enlace a PayPal). Proporciona un enlace directo a la FavoritesPage.

⚙️ Configuración y Ejecución
Requisitos Previos
Flutter SDK instalado y configurado.

Un editor de código (como VS Code o Android Studio).

Un emulador o dispositivo físico para ejecutar la aplicación.

Pasos para Ejecutar
Clona el repositorio:

git clone https://github.com/develop4God/Devocional_nuevo.git

Navega al directorio del proyecto:

cd Devocional_nuevo

Obtén las dependencias de Flutter:

flutter pub get

Ejecuta la aplicación:

flutter run

Asegúrate de tener un emulador o dispositivo conectado y seleccionado.

English (EN)
This is a Flutter mobile application designed to offer daily biblical devotionals. The application dynamically loads content from a remote API (a GitHub repository serving JSON files) and allows users to read, navigate, bookmark devotionals as favorites, share content, and manage some basic preferences.

🚀 Key Features
Daily Devotionals: Access to a different devotional each day.

Multi-Version Support: Devotionals can be available in different Bible versions (e.g., KJV, RVR1960).

Favorites: Save your preferred devotionals for easy future access.

Content Sharing: Share devotionals as text or as an image (screenshot) through other applications.

Prayer of Faith: Includes a prayer of faith that can be displayed or disabled.

Language Customization: Prepared to support multiple languages (currently configured for Spanish).

Intuitive Interface: Easy navigation between devotionals and app sections.

🏗️ Architecture and Key Components
The application is built using the Flutter framework and follows principles of modular architecture and state management with Provider.

Application Architecture Diagram
graph TD
    subgraph Devotional App
        A[main.dart<br>(Entry Point)] --> B(SplashScreen<br>(Initial Animation))
        B --> C(AppInitializer<br>(Data Loading & Setup))
        C --> D(DevocionalesPage<br>(Main Content))

        D -- Navigates to --> E(SettingsPage<br>(Options/Settings))
        D -- Toggles/Manages --> F(DevocionalProvider<br>(State/Data Management))

        E -- Navigates to --> G(FavoritesPage<br>(Favorite Devotionals))
        G -- Navigates back to --> D

        F -- Fetches Data From --> H(Remote API<br>(GitHub JSON))
        F -- Saves/Loads Data --> I(SharedPreferences<br>(Local Data))
        F -- Uses Structure --> J(DevocionalModel<br>(Data Models))

        K(HomePage<br>(Optional Tab Container))
    end

    subgraph Key Components
        J -- Defines Structure --> Devotional{Devotional & ParaMeditar}
        H -- API URL from --> L(constants.dart<br>(Constants/URLs))
    end

    style D fill:#f9f,stroke:#333,stroke-width:2px
    style G fill:#f9f,stroke:#333,stroke-width:2px
    style E fill:#f9f,stroke:#333,stroke-width:2px
    style F fill:#ADD8E6,stroke:#333,stroke-width:2px
    style J fill:#FFD700,stroke:#333,stroke-width:2px
    style K fill:#D3D3D3,stroke:#333,stroke-width:1px

Description of Key Files (lib folder)
main.dart:

Purpose: Application entry point.

Functionality: Initializes Flutter, configures date internationalization, wraps the application in ChangeNotifierProvider for DevocionalProvider, defines the global visual theme, and sets SplashScreen as the initial screen.

splash_screen.dart:

Purpose: Initial loading screen.

Functionality: Displays a fading animation with a background image and a message. After a short delay, it navigates to AppInitializer to begin the actual data loading.

app_initializer.dart:

Purpose: Handles asynchronous application data initialization.

Functionality: Uses Provider to access the DevocionalProvider and calls its initializeData() method. Once data is loaded (or an error occurs), it navigates to DevocionalesPage.

providers/devocional_provider.dart:

Purpose: Manages the state and data of the devotionals throughout the application.

Functionality:

Loads all devotionals for a specific year from a remote JSON (served via GitHub).

Filters devotionals by the selected Bible version (e.g., RVR1960).

Manages the user's list of favorite devotionals, saving and loading them using shared_preferences.

Manages the preference to show or hide a "Prayer of Faith" dialog.

Notifies listening widgets of any state changes (e.g., data loaded, favorite added).

models/devocional_model.dart:

Purpose: Defines the data structures (Devocional and ParaMeditar) used to represent the devotional content.

Functionality: Includes factory constructors (fromJson) to parse JSON objects into Dart instances, and toJson methods to serialize Dart instances into JSON objects (useful for saving favorites).

utils/constants.dart:

Purpose: Stores global constants and utilities.

Functionality: Contains the getDevocionalesApiUrl function to construct the URL for the devotional JSON file on GitHub, based on the year. Also defines keys for SharedPreferences.

pages/devocionales_page.dart:

Purpose: Displays the current devotional with interaction options.

Functionality:

Shows the verse, reflection, "for meditation," and prayer of the current devotional.

Allows navigation between previous and next devotionals.

Integrates buttons to mark/unmark as favorite, share content as text or a screenshot, and access the settings page.

Displays the "Prayer of Faith" dialog under certain conditions.

pages/favorites_page.dart:

Purpose: Displays the list of devotionals marked as favorites.

Functionality: Presents a scrollable list of favorite devotional cards. Clicking a card navigates back to the DevocionalesPage to display that specific devotional. Allows removing devotionals from the favorites list.

pages/home_page.dart:

Purpose: (Potential) To serve as the main container with tab navigation.

Functionality: Defines a BottomNavigationBar to switch between DevocionalesPage, FavoritesPage, and a placeholder SettingsPage. Note: In the current application flow, this HomePage is not directly used as the main screen after initialization, but it represents a common navigation structure in Flutter apps.

pages/settings_page.dart:

Purpose: Offers configuration options and external links.

Functionality: Allows the user to change the application's language (currently only Spanish). Includes a button for donations (PayPal link). Provides a direct link to the FavoritesPage.

⚙️ Setup and Execution
Prerequisites
Flutter SDK installed and configured.

A code editor (like VS Code or Android Studio).

An emulator or physical device to run the app.

Steps to Run
Clone the repository:

git clone https://github.com/develop4God/Devocional_nuevo.git

Navigate to the project directory:

cd Devocional_nuevo

Get Flutter dependencies:

flutter pub get

Run the application:

flutter run

Make sure you have an emulator or device connected and selected.
