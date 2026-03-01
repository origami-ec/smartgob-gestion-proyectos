package ec.smartgob.gproyectos.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.stream.Collectors;

@Component
@Slf4j
public class JwtTokenProvider {

    @Value("${app.security.jwt.secret}")
    private String jwtSecret;

    @Value("${app.security.jwt.expiration-ms}")
    private long jwtExpirationMs;

    @Value("${app.security.jwt.refresh-expiration-ms}")
    private long refreshExpirationMs;

    private SecretKey key;

    @PostConstruct
    public void init() {
        this.key = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
    }

    public String generateToken(SmartGobUserDetails user) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("colaboradorId", user.getColaboradorId().toString());
        claims.put("nombre", user.getNombreCompleto());
        claims.put("correo", user.getCorreo());
        claims.put("superUsuario", user.isEsSuperUsuario());
        claims.put("roles", user.getAuthorities().stream().map(Object::toString).toList());
        claims.put("rolesPorEquipo", user.getRolesPorEquipo().entrySet().stream()
                .collect(Collectors.toMap(e -> e.getKey().toString(), Map.Entry::getValue)));

        Date now = new Date();
        return Jwts.builder()
                .subject(user.getCedula())
                .claims(claims)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + jwtExpirationMs))
                .signWith(key, Jwts.SIG.HS256)
                .compact();
    }

    public String generateRefreshToken(String cedula) {
        Date now = new Date();
        return Jwts.builder()
                .subject(cedula).claim("type", "refresh")
                .issuedAt(now).expiration(new Date(now.getTime() + refreshExpirationMs))
                .signWith(key, Jwts.SIG.HS256).compact();
    }

    @SuppressWarnings("unchecked")
    public Authentication getAuthentication(String token) {
        Claims claims = parseClaims(token);
        UUID colabId = UUID.fromString(claims.get("colaboradorId", String.class));
        boolean su = Boolean.TRUE.equals(claims.get("superUsuario", Boolean.class));

        List<String> roles = claims.get("roles", List.class);
        var auths = roles.stream().map(SimpleGrantedAuthority::new).collect(Collectors.toList());

        Map<String, String> rpeStr = claims.get("rolesPorEquipo", Map.class);
        Map<UUID, String> rpe = new HashMap<>();
        if (rpeStr != null) rpeStr.forEach((k, v) -> rpe.put(UUID.fromString(k), v));

        SmartGobUserDetails ud = new SmartGobUserDetails(
            colabId, claims.getSubject(), claims.get("nombre", String.class),
            claims.get("correo", String.class), "", su, rpe, Map.of());

        return new UsernamePasswordAuthenticationToken(ud, null, auths);
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            log.warn("JWT inválido: {}", e.getMessage());
        }
        return false;
    }

    private Claims parseClaims(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
    }
}
