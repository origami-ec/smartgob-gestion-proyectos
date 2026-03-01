package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.AsignacionEquipo;
import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.dto.request.LoginRequest;
import ec.smartgob.gproyectos.dto.response.AuthResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.repository.AsignacionEquipoRepository;
import ec.smartgob.gproyectos.repository.ColaboradorRepository;
import ec.smartgob.gproyectos.security.JwtTokenProvider;
import ec.smartgob.gproyectos.security.SmartGobUserDetails;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final ColaboradorRepository colaboradorRepo;
    private final AsignacionEquipoRepository asignacionRepo;
    private final JwtTokenProvider jwtProvider;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        Colaborador colaborador = colaboradorRepo.findByCedula(request.getUsuario())
                .or(() -> colaboradorRepo.findByCorreo(request.getUsuario()))
                .orElseThrow(() -> new ResourceNotFoundException("Colaborador", request.getUsuario()));

        if (!"ACTIVO".equals(colaborador.getEstado())) {
            throw new BusinessException("La cuenta se encuentra inactiva");
        }
        if (colaborador.getPasswordHash() == null ||
                !passwordEncoder.matches(request.getPassword(), colaborador.getPasswordHash())) {
            throw new BusinessException("Credenciales inválidas");
        }

        SmartGobUserDetails userDetails = buildUserDetails(colaborador);
        String token = jwtProvider.generateToken(userDetails);

        List<AuthResponse.RolEquipoInfo> rolesInfo = userDetails.getRolesPorEquipo().entrySet().stream()
                .map(e -> AuthResponse.RolEquipoInfo.builder()
                        .equipoId(e.getKey())
                        .rol(e.getValue())
                        .build())
                .toList();

        log.info("Login exitoso: {} ({})", colaborador.getNombreCompleto(), colaborador.getCedula());

        return AuthResponse.builder()
                .token(token)
                .colaboradorId(colaborador.getId())
                .nombreCompleto(colaborador.getNombreCompleto())
                .correo(colaborador.getCorreo())
                .esSuperUsuario(Boolean.TRUE.equals(colaborador.getEsSuperUsuario()))
                .roles(rolesInfo)
                .build();
    }

    public SmartGobUserDetails buildUserDetails(Colaborador colaborador) {
        List<AsignacionEquipo> asignaciones = asignacionRepo
                .findByColaboradorIdConEquipo(colaborador.getId());

        Map<UUID, String> rolesPorEquipo = asignaciones.stream()
                .collect(Collectors.toMap(
                        ae -> ae.getEquipo().getId(),
                        AsignacionEquipo::getRolEquipo,
                        (a, b) -> a));

        Map<UUID, Set<UUID>> contratosAccesibles = asignaciones.stream()
                .collect(Collectors.groupingBy(
                        ae -> ae.getEquipo().getContrato().getId(),
                        Collectors.mapping(ae -> ae.getEquipo().getId(), Collectors.toSet())));

        return new SmartGobUserDetails(
                colaborador.getId(), colaborador.getCedula(),
                colaborador.getNombreCompleto(), colaborador.getCorreo(),
                colaborador.getPasswordHash() != null ? colaborador.getPasswordHash() : "",
                Boolean.TRUE.equals(colaborador.getEsSuperUsuario()),
                rolesPorEquipo, contratosAccesibles);
    }
}
