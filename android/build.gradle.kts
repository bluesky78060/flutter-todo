allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// --- home_widget 0.8.1 의 열린 버전 범위 때문에 생기는 빌드 파손 대응 ---
//
// 이 플러그인은 androidx.glance 를 "1.+", androidx.work 를 "2.+" 로 선언해 두고
// 자신의 jvmTarget 은 "1.8" 로 고정해 두었다. androidx 쪽이 올라갈 때마다
// 이 저장소의 빌드가 같이 흔들린다. 지금까지 두 가지로 터졌다.
//
//  1) androidx 가 JVM 11 바이트코드로 올라가 1.8 로 인라인 불가
//     → :home_widget:compileReleaseKotlin 실패
//  2) glance 가 1.3.0-alpha02 로 잡히는데 이건 AGP 9.1.0 을 요구
//     → 이 프로젝트(AGP 8.9.1)에서 해석 단계부터 실패
//
// 플러그인을 고칠 수 없으므로 소비하는 쪽에서 막는다.

// (1) home_widget 만 11 로 올린다. 전체에 걸면 Java 17 로 빌드되는 다른 플러그인
//     (battery_plus 등)에서 Java/Kotlin 타깃 불일치가 난다.
//     afterEvaluate 는 플러그인이 자기 build.gradle 에 써 둔 값을 덮기 위해 필요하다.
subprojects {
    if (name == "home_widget") {
        afterEvaluate {
            extensions.findByName("android")?.let { ext ->
                (ext as com.android.build.gradle.LibraryExtension).compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_11
                    targetCompatibility = JavaVersion.VERSION_11
                }
            }
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
            }
        }
    }
}

// (2) glance 고정. home_widget 에만 걸면 안 된다 — AGP 호환성 검사는 :app 이
//     의존성 그래프 전체를 해석할 때 돌기 때문에 :app 의 설정에도 들어가야 한다.
allprojects {
    configurations.configureEach {
        resolutionStrategy {
            force("androidx.glance:glance-appwidget:1.1.1")
            force("androidx.glance:glance:1.1.1")
        }
    }
}
