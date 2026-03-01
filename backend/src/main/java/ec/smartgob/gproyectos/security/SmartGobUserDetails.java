package ec.smartgob.gproyectos.security;

import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.*;
import java.util.stream.Collectors;

@Getter
public class SmartGobUserDetails implements UserDetails {

    private final UUID colaboradorId;
    private final String cedula;
    private final String nombreCompleto;
    private final String correo;
    private final String password;
    private final boolean esSuperUsuario;
    private final Map<UUID, String> rolesPorEquipo;
    private final Map<UUID, Set<UUID>> contratosAccesibles;
    private final Collection<? extends GrantedAuthority> authorities;

    public SmartGobUserDetails(UUID colaboradorId, String cedula, String nombreCompleto,
                                String correo, String password, boolean esSuperUsuario,
                                Map<UUID, String> rolesPorEquipo,
                                Map<UUID, Set<UUID>> contratosAccesibles) {
        this.colaboradorId = colaboradorId;
        this.cedula = cedula;
        this.nombreCompleto = nombreCompleto;
        this.correo = correo;
        this.password = password;
        this.esSuperUsuario = esSuperUsuario;
        this.rolesPorEquipo = rolesPorEquipo != null ? rolesPorEquipo : Map.of();
        this.contratosAccesibles = contratosAccesibles != null ? contratosAccesibles : Map.of();

        Set<GrantedAuthority> auths = new HashSet<>();
        if (esSuperUsuario) auths.add(new SimpleGrantedAuthority("ROLE_SUPER_USUARIO"));
        this.rolesPorEquipo.values().stream().distinct()
            .forEach(r -> auths.add(new SimpleGrantedAuthority("ROLE_" + r)));
        this.authorities = Collections.unmodifiableSet(auths);
    }

    @Override public String getUsername() { return cedula; }
    @Override public boolean isAccountNonExpired() { return true; }
    @Override public boolean isAccountNonLocked() { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
    @Override public boolean isEnabled() { return true; }

    public Optional<String> getRolEnEquipo(UUID equipoId) {
        if (esSuperUsuario) return Optional.of(RoleConstants.SUPER_USUARIO);
        return Optional.ofNullable(rolesPorEquipo.get(equipoId));
    }

    public boolean tieneAccesoContrato(UUID contratoId) {
        return esSuperUsuario || contratosAccesibles.containsKey(contratoId);
    }

    public boolean esGestorEnEquipo(UUID equipoId) {
        if (esSuperUsuario) return true;
        return RoleConstants.esRolGestion(rolesPorEquipo.get(equipoId));
    }
}
