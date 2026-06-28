package xiaopa.pclexitcrashfix.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.Coerce;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

import java.lang.reflect.InvocationTargetException;

@Mixin(targets = "net.fabricmc.fabric.impl.registry.sync.RegistrySyncManager", remap = false)
public abstract class RegistrySyncManagerMixin {
    @Redirect(
            method = "unmap",
            at = @At(
                    value = "INVOKE",
                    target = "Lnet/fabricmc/fabric/impl/registry/sync/RemappableRegistry;unmap(Ljava/lang/String;)V"
            ),
            remap = false
    )
    private static void pclExitCrashFix$safelyUnmapRegistry(@Coerce Object registry, String registryId) {
        try {
            registry.getClass().getMethod("unmap", String.class).invoke(registry, registryId);
        } catch (Throwable throwable) {
            Throwable actual = throwable instanceof InvocationTargetException && throwable.getCause() != null
                    ? throwable.getCause()
                    : throwable;
            System.err.println("[PCLExitCrashFix] Skipped Fabric registry unmap for '" + registryId
                    + "' to avoid disconnect crash: " + actual);
        }
    }

    @Redirect(
            method = "apply",
            at = @At(
                    value = "INVOKE",
                    target = "Lnet/fabricmc/fabric/impl/registry/sync/RemappableRegistry;remap(Ljava/lang/String;Lit/unimi/dsi/fastutil/objects/Object2IntMap;Lnet/fabricmc/fabric/impl/registry/sync/RemappableRegistry$RemapMode;)V"
            ),
            remap = false
    )
    private static void pclExitCrashFix$safelyRemapRegistry(@Coerce Object registry, String registryId,
                                                             @Coerce Object registryMap, @Coerce Object mode) {
        try {
            Class<?> object2IntMapClass = Class.forName("it.unimi.dsi.fastutil.objects.Object2IntMap");
            Class<?> remapModeClass = Class.forName("net.fabricmc.fabric.impl.registry.sync.RemappableRegistry$RemapMode");
            registry.getClass()
                    .getMethod("remap", String.class, object2IntMapClass, remapModeClass)
                    .invoke(registry, registryId, registryMap, mode);
        } catch (Throwable throwable) {
            Throwable actual = throwable instanceof InvocationTargetException && throwable.getCause() != null
                    ? throwable.getCause()
                    : throwable;
            System.err.println("[PCLExitCrashFix] Skipped Fabric registry remap for '" + registryId
                    + "' to avoid reconnect failure: " + actual);
        }
    }
}
