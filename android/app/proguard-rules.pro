# Keep Flutter's internal utility classes
-keep class io.flutter.util.PathUtils { *; }
-keep class io.flutter.** { *; }

# Keep all classes from path_provider plugin
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep generic Flutter embedding classes
-keep class io.flutter.embedding.** { *; }