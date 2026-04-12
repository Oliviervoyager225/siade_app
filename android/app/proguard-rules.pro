# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# androidx.window extensions (referenced by window library, optional at runtime)
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**
-keep class androidx.window.extensions.** { *; }
-keep class androidx.window.sidecar.** { *; }

# Kotlin metadata (play-services compiled with Kotlin 2.2.0)
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Agora
-keep class io.agora.** { *; }

# Google Play Core (used by Flutter deferred components, optional at runtime)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# General
-keepattributes SourceFile,LineNumberTable
