# Standard ProGuard Rules for Kite

# 1. Obfuscation & Optimization
# We enable obfuscation and optimization for smaller size.
# To disable obfuscation (e.g. for better crash logs), uncomment: -dontobfuscate

# 2. Flutter Internal Rules
# (Managed automatically by Flutter Gradle Plugin)

# 3. YouTubeDL Android & JNI preservation
# These are the critical native interfaces that MUST be kept for functionality.
-keep class com.yausername.youtubedl_android.** { *; }
-keep interface com.yausername.youtubedl_android.** { *; }
-keep class com.yausername.ffmpeg.** { *; }
-keep class com.yausername.aria2c.** { *; }
-keep class io.github.junkfood02.** { *; }
-keep interface io.github.junkfood02.** { *; }

# General JNI method handling
-keepclasseswithmembernames class * {
    native <methods>;
}

# 4. Standard preserves (Keep attributes like Annotations and Signatures)
-keepattributes *Annotation*, EnclosingMethod, Signature
-keepclassmembers class * {
    @androidx.annotation.Keep <methods>;
    @androidx.annotation.Keep <fields>;
}
-keep @androidx.annotation.Keep class * {*;}

# 5. Desugaring and Coroutines
-dontwarn java.beans.**
-dontwarn javax.xml.stream.**
-dontwarn org.apache.commons.compress.**
-dontwarn com.yausername.**
-dontwarn io.github.junkfood02.**

# 6. Kite Application Core
# Keep the main activity and any classes called via reflection (if any)
-keep class com.zenzer0s.kite.MainActivity { *; }
