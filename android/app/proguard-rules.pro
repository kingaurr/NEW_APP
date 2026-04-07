# Keep Flutter's internal utility classes
-keep class io.flutter.util.PathUtils { *; }
-keep class io.flutter.** { *; }

# Keep path_provider plugin classes
-keep class io.flutter.plugins.pathprovider.** { *; }

# Ignore missing Google Play Core classes (they are optional)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**