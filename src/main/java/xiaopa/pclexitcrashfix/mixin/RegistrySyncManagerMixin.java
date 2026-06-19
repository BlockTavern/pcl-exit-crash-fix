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
}
