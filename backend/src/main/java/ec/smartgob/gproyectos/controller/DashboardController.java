package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.dto.response.*;
import ec.smartgob.gproyectos.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/gestion-proyectos/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService service;

    @GetMapping("/super")
    public ResponseEntity<ApiResponse<List<DashboardSuperResponse>>> dashboardSuper() {
        return ResponseEntity.ok(ApiResponse.ok(service.dashboardSuper()));
    }

    @GetMapping("/equipo")
    public ResponseEntity<ApiResponse<List<DashboardEquipoResponse>>> dashboardEquipo(
            @RequestParam(required = false) UUID contratoId) {
        return ResponseEntity.ok(ApiResponse.ok(service.dashboardEquipo(contratoId)));
    }

    @GetMapping("/carga-colaborador")
    public ResponseEntity<ApiResponse<List<CargaColaboradorResponse>>> cargaColaborador(
            @RequestParam(required = false) UUID equipoId) {
        return ResponseEntity.ok(ApiResponse.ok(service.cargaColaborador(equipoId)));
    }

    @GetMapping("/alertas-sla")
    public ResponseEntity<ApiResponse<List<TareaAlertaResponse>>> alertasSla(
            @RequestParam(required = false) UUID contratoId,
            @RequestParam(required = false) UUID equipoId,
            @RequestParam(required = false) String alertaSla) {
        return ResponseEntity.ok(ApiResponse.ok(
                service.tareasConAlerta(contratoId, equipoId, alertaSla)));
    }

    @GetMapping("/kanban-conteo/{equipoId}")
    public ResponseEntity<ApiResponse<Map<String, Long>>> conteoKanban(@PathVariable UUID equipoId) {
        return ResponseEntity.ok(ApiResponse.ok(service.conteoKanban(equipoId)));
    }
}
