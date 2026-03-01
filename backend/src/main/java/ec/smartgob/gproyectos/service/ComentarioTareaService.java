package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.domain.model.ComentarioTarea;
import ec.smartgob.gproyectos.domain.model.Tarea;
import ec.smartgob.gproyectos.dto.mapper.ComentarioMapper;
import ec.smartgob.gproyectos.dto.request.CrearComentarioRequest;
import ec.smartgob.gproyectos.dto.response.ComentarioResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.repository.ComentarioTareaRepository;
import ec.smartgob.gproyectos.repository.TareaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ComentarioTareaService {

    private final ComentarioTareaRepository comentarioRepo;
    private final TareaRepository tareaRepo;
    private final ComentarioMapper mapper;

    @Transactional(readOnly = true)
    public List<ComentarioResponse> listarPorTarea(UUID tareaId) {
        return comentarioRepo.findByTareaIdOrdenado(tareaId).stream()
                .map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public PageResponse<ComentarioResponse> listarPorTareaPaginado(UUID tareaId, Pageable pageable) {
        return PageResponse.of(
                comentarioRepo.findByTareaIdPaginado(tareaId, pageable),
                mapper::toResponse);
    }

    @Transactional
    public ComentarioResponse crear(UUID tareaId, CrearComentarioRequest request, UUID autorId) {
        Tarea tarea = tareaRepo.findById(tareaId)
                .orElseThrow(() -> new ResourceNotFoundException("Tarea", tareaId.toString()));

        ComentarioTarea comentario = ComentarioTarea.builder()
                .tarea(tarea)
                .autor(new Colaborador(autorId))
                .contenido(request.getContenido())
                .tipo(request.getTipo() != null ? request.getTipo() : "COMENTARIO")
                .createdAt(OffsetDateTime.now())
                .build();

        comentario = comentarioRepo.save(comentario);
        return mapper.toResponse(comentarioRepo.findById(comentario.getId())
                .map(c -> { c.getAutor().getNombreCompleto(); return c; })
                .orElse(comentario));
    }

    @Transactional
    public void eliminar(UUID comentarioId) {
        if (!comentarioRepo.existsById(comentarioId)) {
            throw new ResourceNotFoundException("Comentario", comentarioId.toString());
        }
        comentarioRepo.deleteById(comentarioId);
    }
}
