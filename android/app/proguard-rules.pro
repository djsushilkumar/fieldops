# FieldOps ProGuard / R8 Release Optimization Rules

# Flutter Embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SQLite3 and Native C/C++ SQLite Libs
-keep class org.sqlite.** { *; }
-keep class com.github.davidmoten.rx.jdbc.** { *; }
-keep class androidx.sqlite.** { *; }
-dontwarn org.sqlite.**
-keepclasseswithmembernames class * {
    native <methods>;
}

# Image Picker and Camera
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

# Geolocator & Location Providers
-keep class com.baseflow.geolocator.** { *; }
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.baseflow.geolocator.**

# Jackson / JSON / Serialization
-keepattributes *Annotation*,EnclosingMethod,Signature,InnerClasses
-dontwarn javax.annotation.**
