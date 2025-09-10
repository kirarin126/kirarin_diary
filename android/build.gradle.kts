// android/build.gradle.kts

// 1. 顶级仓库配置（用于插件解析）
repositories {
    // 国内镜像
    maven { url = uri("https://maven.aliyun.com/repository/google") }
    maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
    // 官方源（后备）
    google()
    mavenCentral()
    gradlePluginPortal()
}

// 2. 所有子项目的仓库配置
allprojects {
    repositories {
        // 国内镜像
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        // 官方源（后备）
        google()
        mavenCentral()
    }
}

// 3. 其余 Flutter 项目默认配置保持不变
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