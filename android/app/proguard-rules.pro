# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core (Dynamic Features, Deferred Components)
-keep class com.google.android.play.** { *; }
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# GSON, Jackson, Moshi, etc.
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepclasseswithmembers class * {
    public <init>(org.json.JSONObject);
}

# Platform channels and native code
-keep class * extends java.util.ListResourceBundle {
    protected Object[][] getContents();
}
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference
-keep public class * extends android.view.View
-keep public class com.android.vending.licensing.ILicensingService

# SQLite
-keep class * extends android.database.sqlite.SQLiteOpenHelper

# If you use Google Maps, uncomment
#-keep class com.google.android.gms.maps.** { *; }
#-keep interface com.google.android.gms.maps.** { *; }
#-keep class com.google.maps.** { *; }

# If you use Google AdMob, uncomment
#-keep class com.google.android.gms.ads.** { *; }
#-dontwarn com.google.android.gms.ads.**

# If you use Facebook, uncomment
#-keep class com.facebook.** { *; }
#-dontwarn com.facebook.**

# If you use other SDKs, add their rules here

# Prevent obfuscation of platform channel classes
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.plugin.platform.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class android.support.** { *; }
-keep class androidx.** { *; }
-keep public class * extends android.app.Activity
-keep public class * extends androidx.fragment.app.Fragment
-keep public class * extends android.app.Fragment
