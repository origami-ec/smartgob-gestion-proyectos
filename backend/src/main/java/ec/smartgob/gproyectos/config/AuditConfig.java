package ec.smartgob.gproyectos.config;

import ec.smartgob.gproyectos.security.SmartGobUserDetails;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.AuditorAware;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

@Configuration
public class AuditConfig {

    @Bean
    public AuditorAware<String> auditorProvider() {
        return () -> {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null || !auth.isAuthenticated()
                    || "anonymousUser".equals(auth.getPrincipal())) {
                return Optional.of("SYSTEM");
            }
            if (auth.getPrincipal() instanceof SmartGobUserDetails ud) {
                return Optional.of(ud.getColaboradorId().toString());
            }
            return Optional.of(auth.getName());
        };
    }
}
