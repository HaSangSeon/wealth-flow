# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Deferred Components (Play Core not used)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Google Mobile Ads (AdMob)
-keep public class com.google.android.gms.ads.** {
   public *;
}
-keep public class com.google.ads.** {
   public *;
}
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.ads.**

# Hive
-keep class io.flutter.plugins.hive.** { *; }

# Workmanager
-keep class dev.fluttercommunity.workmanager.** { *; }
-keep class androidx.work.** { *; }

# RevenueCat / Purchases
-keep class com.revenuecat.purchases.** { *; }

# HomeWidget
-keep class es.antonborri.home_widget.** { *; }
-keep class com.hadoseo.wealthflow.WealthWidgetProvider { *; }

# Protocol Buffers / Gson / Serialization
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**
