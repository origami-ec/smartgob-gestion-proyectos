package ec.smartgob.gproyectos.config;

import ec.smartgob.gproyectos.security.SmartGobUserDetails;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.*;

/**
 * Helpers para simular autenticación en tests.
 */
@TestConfiguration
public class TestSecurityConfig {

    public static SmartGobUserDetails createTestUser(UUID colaboradorId, boolean superUsuario) {
        Map<UUID, String> rolesPorEquipo = new HashMap<>();
        Set<UUID> contratosAccesibles = new HashSet<>();

        return new SmartGobUserDetails(
                colaboradorId,
                "test@smartgob.ec",
                "Test User",
                "$2a$10$test",
                superUsuario,
                rolesPorEquipo,
                contratosAccesibles,
                List.of(new SimpleGrantedAuthority("ROLE_USER"))
        );
    }

    public static SmartGobUserDetails createTestUserWithRole(UUID colaboradorId, UUID equipoId, String rol) {
        Map<UUID, String> rolesPorEquipo = Map.of(equipoId, rol);
        Set<UUID> contratosAccesibles = new HashSet<>();

        return new SmartGobUserDetails(
                colaboradorId,
                "test@smartgob.ec",
                "Test User",
                "$2a$10$test",
                false,
                rolesPorEquipo,
                contratosAccesibles,
                List.of(new SimpleGrantedAuthority("ROLE_USER"))
        );
    }

    public static void authenticateAs(SmartGobUserDetails userDetails) {
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
        SecurityContext ctx = SecurityContextHolder.createEmptyContext();
        ctx.setAuthentication(auth);
        SecurityContextHolder.setContext(ctx);
    }

    public static void clearAuth() {
        SecurityContextHolder.clearContext();
    }
}
