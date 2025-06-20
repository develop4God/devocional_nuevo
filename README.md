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

Diagrama de Arquitectura Técnica de la Aplicación
Este diagrama ilustra las principales pantallas, los proveedores de datos y las interacciones clave dentro de tu aplicación de devocionales.

graph TD
    subgraph Capa de Presentación (UI)
        A[main.dart<br>Punto de Entrada] --> B(SplashScreen<br>Animación Inicial)
        B -- Navega a --> C(AppInitializer<br>Carga de Datos)
        C -- Inicialización Completa --> D(DevocionalesPage<br>Contenido Principal<br>[Image: Devocional Diario])
        D -- Acción de Usuario --> E(SettingsPage<br>Opciones/Ajustes<br>[Image: Pantalla de Ajustes])
        D -- Acción de Usuario --> G(FavoritesPage<br>Devocionales Favoritos<br>[Image: Lista de Favoritos])

        E -- Navega a --> G
        G -- Toca Devocional --> D
    end

    subgraph Capa de Lógica y Datos
        F(DevocionalProvider<br>Gestión de Estado y Datos<br>Notificador)
        J(DevocionalModel<br>Definición de Modelos)
        L(Constants.dart<br>URLs y Constantes)
        I(SharedPreferences<br>Almacenamiento Local)
        H(API Remota<br>GitHub JSON Devocionales)
    end

    C -- Accede y Llama Métodos --> F
    D -- Consume Datos de UI --> F
    E -- Modifica Preferencias --> F
    G -- Consume Datos de UI --> F
    F -- Carga/Actualiza Datos --> H
    F -- Persiste/Lee Preferencias --> I
    F -- Serializa/Deserializa --> J
    H -- URL de Contenido --> L
    J -- Define Estructura --> Devocional{Devocional y Para Meditar Objetos}

    style D fill:#f9f,stroke:#333,stroke-width:2px
    style G fill:#f9f,stroke:#333,stroke-width:2px
    style E fill:#f9f,stroke:#333,stroke-width:2px
    style F fill:#ADD8E6,stroke:#333,stroke-width:2px
    style J fill:#FFD700,stroke:#333,stroke-width:2px
    style I fill:#lightgreen,stroke:#333,stroke-width:2px
    style H fill:#FFB6C1,stroke:#333,stroke-width:2px
    style L fill:#90EE90,stroke:#333,stroke-width:2px

Descripción del Flujo Técnico y Componentes:

main.dart: Punto de entrada de la aplicación. Configura el tema, la localización y el DevocionalProvider global utilizando ChangeNotifierProvider, y lanza la SplashScreen.

SplashScreen: La primera pantalla visible. Muestra una animación mientras la aplicación se inicializa. Después de un tiempo, navega a AppInitializer.

AppInitializer: Un widget intermedio crucial encargado de la inicialización asíncrona de los datos de la aplicación. Utiliza Provider para acceder al DevocionalProvider y llama a su método initializeData(). Una vez que los datos están cargados (o se produce un error), navega a la DevocionalesPage.

DevocionalProvider: El corazón de la gestión de estado y datos de la aplicación (usando el patrón Provider). Es un ChangeNotifier que:

Carga devocionales desde una API Remota (JSON de GitHub) usando la librería http.

Detecta y gestiona el idioma y la versión seleccionados por el usuario, guardándolos en SharedPreferences (almacenamiento local persistente).

Filtra los devocionales cargados según la versión bíblica seleccionada.

Maneja la lógica de "favoritos" (añadir/quitar) y persiste esta lista en SharedPreferences.

Controla la visibilidad de un "diálogo de invitación" (Oración de Fe), también guardando la preferencia en SharedPreferences.

Notifica a sus consumidores (widgets de UI) sobre cambios en los datos, lo que provoca que la interfaz de usuario se actualice.

DevocionalModel: Define la estructura de datos para un devocional (Devocional) y sus subcomponentes (ParaMeditar). Incluye métodos fromJson y toJson para la serialización y deserialización de datos, facilitando su almacenamiento y recuperación.

constants.dart: Contiene la lógica para construir la URL de la API remota de devocionales (basada en el año) y otras constantes como las claves para SharedPreferences.

DevocionalesPage: La pantalla principal donde los usuarios ven el contenido del devocional del día. Consume los datos del DevocionalProvider, permite la navegación entre devocionales (anterior/siguiente), ofrece opciones para marcar como favorito, compartir (como texto o imagen - captura de pantalla) y navegar a la SettingsPage. Muestra un diálogo de "Oración de Fe" si no se ha deshabilitado.

FavoritesPage: Muestra una lista de todos los devocionales que el usuario ha marcado como favoritos. También consume el DevocionalProvider para obtener la lista de favoritos, permite "quitar de favoritos" y, al tocar un favorito, navega de vuelta a la DevocionalesPage mostrando ese devocional específico.

SettingsPage: La pantalla de ajustes. Permite cambiar el idioma (actualmente solo español, pero preparado para más), incluye un botón para donaciones (enlace a PayPal) y proporciona un enlace directo a la FavoritesPage.

HomePage: (Contenedor de Pestañas Opcional): Aunque existe en el código, no está directamente enlazada en el flujo de inicio actual (main.dart -> SplashScreen -> AppInitializer -> DevocionalesPage). Su propósito es servir como un contenedor con una BottomNavigationBar para navegar entre DevocionalesPage, FavoritesPage y SettingsPage como pestañas. Esto podría ser una evolución futura de la navegación principal.

🚶 Flujo de Usuario (UI/UX)
Este diagrama describe la experiencia del usuario al interactuar con la aplicación, mostrando cómo navegan entre las diferentes pantallas y realizan acciones clave.

graph TD
    A[Inicio App<br>(Usuario Toca Ícono)] --> B(SplashScreen<br>Animación de Carga)
    B -- Tiempo + Carga Datos --> C(DevocionalesPage<br>Ver Devocional Diario<br>[Image: Pantalla Principal Devocional])
    C -- Swipe Izquierda/Botón Siguiente --> C1(DevocionalesPage<br>Ver Siguiente Devocional)
    C -- Swipe Derecha/Botón Anterior --> C2(DevocionalesPage<br>Ver Devocional Anterior)

    C -- Tocar Ícono Corazón --> C3{Devocional Favorito?<br>Sí/No}
    C3 -- Sí --> C4(Remover de Favoritos<br>Mensaje Confirmación)
    C3 -- No --> C5(Añadir a Favoritos<br>Mensaje Confirmación)

    C -- Tocar Ícono Compartir Texto --> C6(Compartir Devocional<br>Como Texto)
    C -- Tocar Ícono Compartir Imagen --> C7(Compartir Devocional<br>Como Captura de Pantalla)

    C -- Tocar Ícono Ajustes --> D(SettingsPage<br>Acceder a Opciones<br>[Image: Pantalla de Ajustes])
    D -- Tocar "Favoritos guardados" --> E(FavoritesPage<br>Ver Lista de Favoritos<br>[Image: Lista de Favoritos])
    E -- Tocar Devocional en Lista --> C

    D -- Tocar "Donar" --> D1(Abrir Navegador<br>Página de PayPal)

    C -- Cada cierto número de devocionales --> F{Mostrar Oración de Fe?<br>Si no marcada "No mostrar"}
    F -- Oración mostrada --> G(Diálogo de Oración<br>"Oración de fe..."<br>[Image: Diálogo de Oración])
    G -- Tocar "Continuar" + (Opcional "No mostrar nuevamente") --> C

    C --> End[Continuar Explorando]
    E --> End
    D --> End

    style C fill:#D3D3D3,stroke:#333,stroke-width:1px
    style D fill:#D3D3D3,stroke:#333,stroke-width:1px
    style E fill:#D3D3D3,stroke:#333,stroke-width:1px

Descripción del Flujo de Usuario:

Inicio de la Aplicación: El usuario toca el ícono de la aplicación.

SplashScreen: Se muestra una animación inicial y un mensaje de carga mientras la aplicación se prepara.

DevocionalesPage (Pantalla Principal): Una vez que los datos están cargados, el usuario es llevado a la pantalla del devocional diario. Aquí puede:

Navegar: Deslizar (swipe) o usar los botones de flecha para ir al devocional anterior o siguiente.

Marcar como Favorito: Tocar el ícono del corazón. Si ya es favorito, se quita de la lista; de lo contrario, se añade. Se muestra un breve mensaje de confirmación.

Compartir: Tocar el ícono de compartir para elegir entre compartir el devocional como texto simple o como una captura de pantalla de la página actual.

Ajustes: Tocar el ícono de ajustes para ir a la SettingsPage.

Oración de Fe: Periódicamente, después de navegar por algunos devocionales, se le puede presentar un diálogo con la "Oración de Fe". El usuario puede leerla y optar por no mostrarla nuevamente.

SettingsPage (Pantalla de Ajustes): Desde aquí, el usuario puede:

Cambiar el idioma de la aplicación (actualmente solo Español está activo).

Tocar un botón "Donar" que abre una página de PayPal en el navegador externo.

Navegar a la FavoritesPage.

FavoritesPage (Pantalla de Favoritos): Muestra una lista de todos los devocionales que el usuario ha marcado previamente. Al tocar un devocional en esta lista, el usuario es llevado de vuelta a la DevocionalesPage, directamente al devocional seleccionado. También puede quitar devocionales de favoritos desde esta lista.

Fin de Interacción: El usuario puede continuar explorando los devocionales o cerrar la aplicación.

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

Application Technical Architecture Diagram
This diagram illustrates the main screens, data providers, and key interactions within your devotional application.

graph TD
    subgraph Presentation Layer (UI)
        A[main.dart<br>Entry Point] --> B(SplashScreen<br>Initial Animation)
        B -- Navigates to --> C(AppInitializer<br>Data Loading)
        C -- Initialization Complete --> D(DevocionalesPage<br>Main Content<br>[Image: Daily Devotional])
        D -- User Action --> E(SettingsPage<br>Options/Settings<br>[Image: Settings Screen])
        D -- User Action --> G(FavoritesPage<br>Favorite Devotionals<br>[Image: Favorites List])

        E -- Navigates to --> G
        G -- Taps Devotional --> D
    end

    subgraph Logic and Data Layer
        F(DevocionalProvider<br>State & Data Management<br>Notifier)
        J(DevocionalModel<br>Model Definitions)
        L(Constants.dart<br>URLs & Constants)
        I(SharedPreferences<br>Local Storage)
        H(Remote API<br>GitHub JSON Devotionals)
    end

    C -- Accesses & Calls Methods --> F
    D -- Consumes UI Data --> F
    E -- Modifies Preferences --> F
    G -- Consumes UI Data --> F
    F -- Loads/Updates Data --> H
    F -- Persists/Reads Preferences --> I
    F -- Serializes/Deserializes --> J
    H -- Content URL from --> L
    J -- Defines Structure --> Devocional{Devocional & ParaMeditar Objects}

    style D fill:#f9f,stroke:#333,stroke-width:2px
    style G fill:#f9f,stroke:#333,stroke-width:2px
    style E fill:#f9f,stroke:#333,stroke-width:2px
    style F fill:#ADD8E6,stroke:#333,stroke-width:2px
    style J fill:#FFD700,stroke:#333,stroke-width:2px
    style I fill:#lightgreen,stroke:#333,stroke-width:2px
    style H fill:#FFB6C1,stroke:#333,stroke-width:2px
    style L fill:#90EE90,stroke:#333,stroke-width:2px

Description of Technical Flow and Components:
main.dart: The application's entry point. It configures the theme, localization, and the global DevocionalProvider using ChangeNotifierProvider, then launches the SplashScreen.

SplashScreen: The first visible screen. It displays an animation while the app initializes. After a short delay, it navigates to AppInitializer.

AppInitializer: A crucial intermediate widget responsible for asynchronous application data initialization. It uses Provider to access the DevocionalProvider and calls its initializeData() method. Once data is loaded (or an error occurs), it navigates to DevocionalesPage.

DevocionalProvider: The core of the application's state and data management (using the Provider pattern). It is a ChangeNotifier that:

Loads devotionals from a Remote API (GitHub JSON) using the http library.

Detects and manages the language and version selected by the user, saving them to SharedPreferences (persistent local storage).

Filters loaded devotionals based on the selected Bible version.

Handles "favorite" logic (add/remove) and persists this list in SharedPreferences.

Controls the visibility of a "Prayer of Faith" dialog, also saving the preference in SharedPreferences.

Notifies its consumers (UI widgets) of any state changes, triggering UI updates.

DevocionalModel: Defines the data structures for a devotional (Devocional) and its sub-components (ParaMeditar). It includes factory constructors (fromJson) to parse JSON objects into Dart instances, and toJson methods to serialize Dart instances to JSON objects (useful for saving favorites).

constants.dart: Contains the logic to construct the URL for the remote devotional JSON API (based on the year) and other constants such as SharedPreferences keys.

DevocionalesPage: The main screen where users view the current devotional content. It consumes data from the DevocionalProvider, allows navigation between previous and next devotionals, offers options to mark as favorite, share (as text or image - screenshot), and navigate to the SettingsPage. It displays a "Prayer of Faith" dialog under certain conditions.

FavoritesPage: Displays a list of all devotionals the user has marked as favorites. It also consumes the DevocionalProvider to get the list of favorites, allows "unfavoriting," and upon tapping a favorite, navigates back to the DevocionalesPage displaying that specific devotional.

SettingsPage: The settings screen. It allows changing the application's language (currently only Spanish is active), includes a button for donations (PayPal link), and provides a direct link to the FavoritesPage.

HomePage: (Optional Tab Container): Although it exists in the code, it's not directly linked in the current application's startup flow (main.dart -> SplashScreen -> AppInitializer -> DevocionalesPage). Its purpose is to serve as a container with a BottomNavigationBar to navigate between DevocionalesPage, FavoritesPage, and SettingsPage as tabs. This could be a future evolution of the main navigation.

🚶 User Flow (UI/UX)
This diagram describes the user experience when interacting with the application, showing how they navigate between different screens and perform key actions.

graph TD
    A[App Launch<br>(User Taps Icon)] --> B(SplashScreen<br>Loading Animation)
    B -- Time + Data Load --> C(DevocionalesPage<br>View Daily Devotional<br>[Image: Main Devotional Screen])
    C -- Swipe Left/Next Button --> C1(DevocionalesPage<br>View Next Devotional)
    C -- Swipe Right/Previous Button --> C2(DevocionalesPage<br>View Previous Devotional)

    C -- Tap Heart Icon --> C3{Devotional Favorite?<br>Yes/No}
    C3 -- Yes --> C4(Remove From Favorites<br>Confirmation Message)
    C3 -- No --> C5(Add to Favorites<br>Confirmation Message)

    C -- Tap Share Text Icon --> C6(Share Devotional<br>As Text)
    C -- Tap Share Image Icon --> C7(Share Devotional<br>As Screenshot)

    C -- Tap Settings Icon --> D(SettingsPage<br>Access Options<br>[Image: Settings Screen])
    D -- Tap "Saved Favorites" --> E(FavoritesPage<br>View Favorites List<br>[Image: Favorites List])
    E -- Tap Devotional in List --> C

    D -- Tap "Donate" --> D1(Open Browser<br>PayPal Page)

    C -- Every N Devotionals --> F{Show Prayer of Faith?<br>If not "Do not show again" checked}
    F -- Prayer Shown --> G(Prayer Dialog<br>"Prayer of faith..."<br>[Image: Prayer Dialog])
    G -- Tap "Continue" + (Optional "Do not show again") --> C

    C --> End[Continue Exploring]
    E --> End
    D --> End

    style C fill:#D3D3D3,stroke:#333,stroke-width:1px
    style D fill:#D3D3D3,stroke:#333,stroke-width:1px
    style E fill:#D3D3D3,stroke:#333,stroke-width:1px

Description of User Flow:

App Launch: The user taps the application icon.

SplashScreen: An initial animation and loading message are displayed while the app prepares.

DevocionalesPage (Main Screen): Once data is loaded, the user is taken to the daily devotional screen. Here they can:

Navigate: Swipe or use arrow buttons to go to the previous or next devotional.

Mark as Favorite: Tap the heart icon. If already a favorite, it's removed; otherwise, it's added. A brief confirmation message is shown.

Share: Tap the share icon to choose between sharing the devotional content as plain text or as a screenshot of the current page.

Settings: Tap the settings icon to go to the SettingsPage.

Prayer of Faith: Periodically, after navigating through some devotionals, a "Prayer of Faith" dialog may be presented. The user can read it and opt not to show it again.

SettingsPage (Settings Screen): From here, the user can:

Change the application language (currently only Spanish is active).

Tap a "Donate" button that opens a PayPal page in the external browser.

Navigate to the FavoritesPage.

FavoritesPage (Favorites Screen): Displays a list of all devotionals the user has previously marked as favorites. Tapping a devotional in this list takes the user back to the DevocionalesPage, directly to the selected devotional. Users can also remove devotionals from the favorites list from here.

End of Interaction: The user can continue exploring devotionals or close the application.
