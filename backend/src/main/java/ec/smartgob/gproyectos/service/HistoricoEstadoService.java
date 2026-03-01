package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.dto.mapper.HistoricoEstadoMapper;
import ec.smartgob.gproyectos.dto.response.HistoricoEstadoResponse;
import ec.smartgob.gproyectos.repository.HistoricoEstadoTareaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class HistoricoEstadoService {

    private final HistoricoEstadoTareaRepository historicoRepo;
    private final HistoricoEstadoMapper mapper;

    @Transactional(readOnly = true)
    public List<HistoricoEstadoResponse> listarPorTarea(UUID tareaId) {
        return historicoRepo.findByTareaIdOrdenado(tareaId).stream()
                .map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public long contarDevoluciones(UUID tareaId) {
        return historicoRepo.countDevoluciones(tareaId);
    }

    @Transactional(readOnly = true)
    public List<HistoricoEstadoResponse> actividadReciente(UUID colaboradorId, int diasAtras) {
        OffsetDateTime desde = OffsetDateTime.now().minusDays(diasAtras);
        return historicoRepo.findActividadReciente(colaboradorId, desde).stream()
                .map(mapper::toResponse).toList();
    }
}
