# PCL Exit Crash Fix

Client-side Fabric workaround for a Minecraft 1.21 modpack crash that happens when disconnecting from a multiplayer server.

The crash this targets looks like:

```text
java.lang.NullPointerException: mouseClicked event handler
at net.minecraft.class_2370.remap
at net.minecraft.class_2370.unmap
at net.fabricmc.fabric.impl.registry.sync.RegistrySyncManager.unmap
```

## What It Does

Fabric API 0.102.0 for Minecraft 1.21 can crash while restoring synced registry mappings during disconnect. This mod redirects each `RemappableRegistry.unmap(registryId)` call and catches failures per registry.

That means:

- registries that can be restored still run normally
- the broken registry entry is skipped instead of crashing the client
- a warning is printed to the log for every skipped registry

This is safer than cancelling the whole Fabric registry unmap process.

## Build With Gradle

```powershell
./gradlew build
```

The jar will be in:

```text
build/libs/pcl-exit-crash-fix-1.1.0.jar
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
