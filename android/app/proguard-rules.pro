# Guardian Mobile - R8 rules for release builds.

# Flutter (deferred components reference Play Core, which is not bundled).
-dontwarn com.google.android.play.core.**
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# App components referenced from the manifest, the MethodChannel and FCM.
-keep class com.guardian.mobile.guardian_mobile.** { *; }

# androidx.security-crypto (Tink) annotations that are compile-only.
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn com.google.api.client.http.**
-dontwarn org.joda.time.**

# OkHttp optional TLS providers.
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn okhttp3.internal.platform.**

# Kotlin coroutines.
-dontwarn kotlinx.coroutines.debug.**

# Firebase Messaging (safe even when google-services.json is absent).
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.**
