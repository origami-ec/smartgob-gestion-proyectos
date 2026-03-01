package ec.smartgob.gproyectos.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.UUID;

/**
 * Utilitario para obtener el usuario autenticado desde el SecurityContext.
 */
public final class SecurityUtils {

    private SecurityUtils() {}

    public static SmartGobUserDetails currentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof SmartGobUserDetails ud)) {
            throw new IllegalStateException("No hay usuario autenticado");
        }
        return ud;
    }

    public static UUID currentUserId() {
        return currentUser().getColaboradorId();
    }

    public static boolean isSuperUsuario() {
        return currentUser().isEsSuperUsuario();
    }
}
