// Packages FORK's native library into a signed Android App Bundle (.aab),
// the format Google Play requires for new apps. The Rust code is built
// first by ../build-aab.sh; this project only wraps it.
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "fork-android"
include(":app")
