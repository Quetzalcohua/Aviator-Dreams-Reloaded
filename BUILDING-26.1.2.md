# 26.1.2 Fabric compatibility port

This branch targets **Minecraft 26.1.2, Fabric only, Java 25**. It is not a
NeoForge port. The retained `neoforge/` and `common/build.gradle` files are upstream
history/reference and are not included by `settings.gradle`.

## Reproducible build

Install a JDK 25 without changing system Java. In PowerShell, from the repository:

```powershell
./scripts/build.ps1 -JavaHome 'C:/path/to/jdk-25' -Clean
```

The script sets JAVA_HOME and GRADLE_USER_HOME only for the current process,
uses the checked-in Gradle wrapper and keeps dependency caches in the repository.
On Unix: set JAVA_HOME to JDK 25 and GRADLE_USER_HOME to `$PWD/.gradle-user-home`,
then run `./gradlew clean :fabric:clean :fabric:build --no-daemon`.

Pinned build dependencies: Gradle 9.6.1, Fabric Loom 1.17.20, Fabric Loader 0.19.5,
Fabric API 0.155.3+26.1.2, Immersive Aircraft **release 1.5.2+26.1.2** from
Conczin Maven (`net.conczin:immersive_aircraft:1.5.2+26.1.2+fabric`).
No local game directory or unpublished Aircraft build is required.

Distributable: `fabric/build/libs/aviator_dreams_reloaded-fabric-1.3.3-port.1+26.1.2.jar`.
The `-sources.jar` is not the playable mod. Minecraft 26.1.2 uses unobfuscated
names; this branch deliberately uses Fabric Loom rather than legacy Architectury
mapping/remapping tasks. Common sources and resources are compiled directly into
the Fabric artifact. Aircraft and Fabric API are dependencies, not shaded copies.

Runtime minimums: JDK 25, Fabric Loader 0.19.5, Fabric API 0.155.3,
Immersive Aircraft 1.5.2; the supported Minecraft version is exactly 26.1.2.
Only the pinned dependency set is intended for acceptance testing.

## Attribution and license

Original author/asset credits in README.md and original LICENSE are retained.
Upstream LICENSE and mod metadata say GPL v3, while the upstream README claims
CC0 excluding textures and bbmodel files. This port does not resolve or relicense
that upstream inconsistency; verify rights with the original authors before
redistributing assets under a different license. The original LICENSE is bundled.

## Verification

See PORT-VALIDATION.md for measured build/runtime results and limitations.
Do not use an existing modpack as the test baseline. Use `fabric/run/` or another
new, disposable directory; never point a development launch at existing saves.

Run `./scripts/verify-jar.ps1` with PowerShell 7 after building to check packaged
metadata, Java 25 bytecode, license and all nine vehicle resource sets. The CI
workflow uses JDK 25, builds only Fabric, and runs this check. CI execution itself
must be confirmed after the parent agent publishes the branch.

The published Aircraft POM includes JEI/REI runtime dependencies used in its own
development environment. The addon explicitly excludes those optional viewers;
its clean runtime test uses only Fabric API and Aircraft, not JEI/REI.

Upstream source baseline: `753ce87485d966312d4442f970eb69e1636d343c`
(`CerealCamera/Aviator-Dreams-Reloaded`, branch `1.21.11`). Actual Java compilation
against 26.1.2 and release Aircraft 1.5.2 found no incompatible addon method
signatures. No speculative method rewrites were introduced: the real migration
is the Java25/unobfuscated Fabric build pipeline, dependency graph and runtime
metadata, validated with a real client rather than just widened version ranges.
