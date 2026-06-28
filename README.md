# PCL Exit Crash Fix

Client-side Fabric workaround for Minecraft 1.21 registry sync issues during disconnect and reconnect.

## Problems Fixed

### 1. Disconnect Crash

Crash when disconnecting from a multiplayer server:

```text
java.lang.NullPointerException: mouseClicked event handler
at net.minecraft.class_2370.remap
at net.minecraft.class_2370.unmap
at net.fabricmc.fabric.impl.registry.sync.RegistrySyncManager.unmap
```

### 2. Reconnect Failure ("Registry remapping failed: null")

After a network drop, reconnecting to the server fails with `Registry remapping failed: null` and the player is immediately kicked. This happens because `unmap()` partially failed on disconnect, leaving registry state inconsistent. When the server sends new registry data on reconnect, `remap()` throws a NullPointerException.

## What It Does

This mod redirects both `RemappableRegistry.unmap(registryId)` and `RemappableRegistry.remap(registryId, ...)` calls inside Fabric API's `RegistrySyncManager`, catching failures per registry.

That means:

- registries that can be restored/remapped still run normally
- a broken registry is skipped instead of crashing or kicking the client
- a warning is printed to the log for every skipped registry

## Build With Gradle

```powershell
./gradlew build
```

The jar will be in:

```text
build/libs/pcl-exit-crash-fix-1.0.1.jar
```

In IntelliJ IDEA, open this folder as the Gradle project and run the `build` task from the Gradle tool window. This project intentionally uses the plain `java-library` plugin instead of Fabric Loom, so Gradle 8.5 is enough.

## Build Locally Without Gradle

From the modpack root:

```powershell
.\pcl-exit-crash-fix\scripts\build-local.ps1
```

That script uses the local Minecraft instance libraries and copies the jar directly into `mods`.

If Minecraft is still running and the old jar is locked, build without installing:

```powershell
.\pcl-exit-crash-fix\scripts\build-local.ps1 -NoInstall
```

Then after closing Minecraft/PCL, install the already-built jar:

```powershell
.\pcl-exit-crash-fix\scripts\install-built.ps1
```

## Remove

Delete this file from `mods`:

```text
pcl-exit-crash-fix-*.jar
```

Then the pack returns to normal Fabric API behavior.
