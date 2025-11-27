# Flutter 기본 규칙 (최소한만 유지)
-keep class io.flutter.app.FlutterActivity { *; }
-keep class io.flutter.embedding.android.FlutterActivity { *; }
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.embedding.engine.dart.DartExecutor { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.view.FlutterMain { *; }

# Gson 규칙 (JSON 직렬화)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp & Retrofit
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Google Sign In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Notification
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class * extends androidx.core.app.NotificationCompat$Style { *; }

# Drift (Database)
-keep class drift.** { *; }
-keep class moor.** { *; }
-dontwarn drift.**
-dontwarn moor.**

# 디버깅을 위한 소스 파일 이름과 라인 번호 유지
-keepattributes SourceFile,LineNumberTable

# 크래시 리포트를 위한 스택 트레이스 정보 유지
-renamesourcefileattribute SourceFile

# Google Play Core (Dynamic Feature Modules)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter Play Store Split Application
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# ============================================================
# 공격적인 최적화 규칙 (크기 감소: 3-4MB)
# ============================================================

# 라이브러리 접근성 축소 (private으로 변환)
-dontskipnonpubliclibraryclasses
-dontskipnonpubliclibraryclassmembers
-allowaccessmodification

# 메서드 및 필드 최적화
-optimizationpasses 5
-optimizations code/simplification/arithmetic,code/simplification/cast,code/allocation/variable
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# 불필요한 속성 제거
-dontwarn org.apache.**
-dontwarn sun.reflect.**
-dontwarn javax.net.ssl.**
-dontwarn java.beans.**
-dontwarn java.lang.management.**
-dontwarn sun.misc.**

# 서명 유지 (필요시에만)
-keepattributes Exceptions,InnerClasses,Signature,LineNumberTable,SourceFile,Deprecated,Synthetic,EnclosingMethod

# 원본 파일명 변경 (더 짧게)
-renamesourcefileattribute SourceFile
