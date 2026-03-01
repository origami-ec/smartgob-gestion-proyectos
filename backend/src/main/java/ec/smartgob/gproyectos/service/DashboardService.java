package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.dto.mapper.DashboardMapper;
import ec.smartgob.gproyectos.dto.mapper.TareaMapper;
import ec.smartgob.gproyectos.dto.response.*;
import ec.smartgob.gproyectos.repository.TareaRepository;
import ec.smartgob.gproyectos.repository.projection.KanbanCountProjection;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final TareaRepository tareaRepo;
    private final DashboardMapper dashboardMapper;
    private final TareaMapper tareaMapper;

    @Transactional(readOnly = true)
    public List<DashboardSuperResponse> dashboardSuper() {
        return tareaRepo.findDashboardSuper().stream()
                .map(dashboardMapper::toSuperResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<DashboardEquipoResponse> dashboardEquipo(UUID contratoId) {
        return tareaRepo.findDashboardEquipo(contratoId).stream()
                .map(dashboardMapper::toEquipoResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<CargaColaboradorResponse> cargaColaborador(UUID equipoId) {
        return tareaRepo.findCargaColaborador(equipoId).stream()
                .map(dashboardMapper::toCargaResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<TareaAlertaResponse> tareasConAlerta(UUID contratoId, UUID equipoId, String alertaSla) {
        return tareaRepo.findTareasConAlertaSla(contratoId, equipoId, alertaSla).stream()
                .map(tareaMapper::toAlertaResponse).toList();
    }

    @Transactional(readOnly = true)
    public Map<String, Long> conteoKanban(UUID equipoId) {
        return tareaRepo.contarPorEstadoYEquipo(equipoId).stream()
                .collect(Collectors.toMap(KanbanCountProjection::getEstado, KanbanCountProjection::getTotal));
    }
}
