# Flutter rules
-dontobfuscate

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# YouTubeDL Android rules - Aggressive keep
-keep class com.yausername.** { *; }
-keep class org.apache.commons.compress.archivers.zip.** { *; }
-keep interface com.yausername.** { *; }
-keep class com.yausername.youtubedl_android.** { *; }
-keep interface com.yausername.youtubedl_android.** { *; }
-keep class com.yausername.ffmpeg.** { *; }
-keep class com.yausername.aria2c.** { *; }

# Junkfood02 specific
-keep class io.github.junkfood02.** { *; }
-keep interface io.github.junkfood02.** { *; }

# JNI & Reflection preservation
-keepattributes *Annotation*,Signature,EnclosingMethod,InnerClasses,SourceFile,LineNumberTable
-keepclasseswithmembernames class * {
    native <methods>;
}

# AndroidX and Compose
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# Kotlin & Coroutines
-keep class kotlin.** { *; }
-keep interface kotlin.** { *; }
-keep class kotlinx.** { *; }
-keep interface kotlinx.** { *; }
-keep class kotlin.reflect.jvm.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# Riverpod & State Management rules
-keep class com.riverpod.** { *; }
-keep class flutter_riverpod.** { *; }
-dontwarn flutter_riverpod.**

# Google Fonts rules
-keep class com.google.fonts.** { *; }
-dontwarn com.google.fonts.**

# Kite App Specific (Full preservation)
-keep class com.zenzer0s.kite.** { *; }

# Ignore missing Java desktop/XML library classes not present on Android
-dontwarn java.beans.**
-dontwarn javax.xml.stream.**
-dontwarn com.fasterxml.jackson.databind.**
-dontwarn org.apache.tika.**
-dontwarn org.apache.james.mime4j.**
-dontwarn com.google.common.collect.**
-dontwarn org.apache.pdfbox.**
-dontwarn org.checkerframework.**

# Fix for Play Core and GMS
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.internal.**
-dontwarn androidx.security.crypto.**
-dontwarn com.yausername.**
-dontwarn io.github.junkfood02.**

# Standard class members keep
-keepclassmembers class * {
    @androidx.annotation.Keep <methods>;
    @androidx.annotation.Keep <fields>;
}
-keep @androidx.annotation.Keep class * {*;}
