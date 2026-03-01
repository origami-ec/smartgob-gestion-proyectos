package ec.smartgob.gproyectos.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.*;

import static org.assertj.core.api.Assertions.*;

class JwtTokenProviderTest {

    private JwtTokenProvider jwtProvider;

    @BeforeEach
    void setUp() {
        jwtProvider = new JwtTokenProvider();
        // Simular propiedades — en prod vienen de application.yml
        jwtProvider.setSecret("testSecretKey256BitsLongForJwtTokenSigningInTests!!");
        jwtProvider.setExpirationMs(3600000L);
    }

    @Test
    @DisplayName("Genera y valida token JWT")
    void generarYValidar() {
        UUID userId = UUID.randomUUID();
        SmartGobUserDetails user = new SmartGobUserDetails(
                userId, "test@test.ec", "Test", "$2a$10$x", false,
                Map.of(), Set.of(), List.of(new SimpleGrantedAuthority("ROLE_USER")));

        String token = jwtProvider.generarToken(user);

        assertThat(token).isNotBlank();
        assertThat(jwtProvider.validarToken(token)).isTrue();
        assertThat(jwtProvider.extraerColaboradorId(token)).isEqualTo(userId.toString());
    }

    @Test
    @DisplayName("Token expirado es inválido")
    void tokenExpirado() {
        jwtProvider.setExpirationMs(-1000L); // ya expirado
        UUID userId = UUID.randomUUID();
        SmartGobUserDetails user = new SmartGobUserDetails(
                userId, "test@test.ec", "Test", "$2a$10$x", false,
                Map.of(), Set.of(), List.of());

        String token = jwtProvider.generarToken(user);

        assertThat(jwtProvider.validarToken(token)).isFalse();
    }

    @Test
    @DisplayName("Token malformado es inválido")
    void tokenMalformado() {
        assertThat(jwtProvider.validarToken("esto-no-es-un-jwt")).isFalse();
        assertThat(jwtProvider.validarToken("")).isFalse();
        assertThat(jwtProvider.validarToken(null)).isFalse();
    }
}
