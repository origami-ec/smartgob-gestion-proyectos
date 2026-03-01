package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.dto.request.LoginRequest;
import ec.smartgob.gproyectos.dto.response.ApiResponse;
import ec.smartgob.gproyectos.dto.response.AuthResponse;
import ec.smartgob.gproyectos.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse auth = authService.login(request);
        return ResponseEntity.ok(ApiResponse.ok(auth, "Login exitoso"));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<AuthResponse>> me() {
        var user = ec.smartgob.gproyectos.security.SecurityUtils.currentUser();
        AuthResponse resp = AuthResponse.builder()
                .colaboradorId(user.getColaboradorId())
                .nombreCompleto(user.getNombreCompleto())
                .correo(user.getCorreo())
                .esSuperUsuario(user.isEsSuperUsuario())
                .build();
        return ResponseEntity.ok(ApiResponse.ok(resp));
    }
}
