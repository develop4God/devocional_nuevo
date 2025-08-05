# Reglas específicas para violaciones de accesibilidad
-dontwarn android.view.accessibility.**
-keep class android.view.accessibility.** { *; }
-dontwarn android.util.**
-keep class android.util.** { *; }

# Reglas específicas para violaciones de ECParameterSpec
-dontwarn java.security.spec.**
-keep class java.security.spec.** { *; }

# Reglas específicas para Socket
-dontwarn java.net.**
-keep class java.net.** { *; }

# Reglas específicas para VMStack
-dontwarn dalvik.system.**
-keep class dalvik.system.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Flutter general
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**