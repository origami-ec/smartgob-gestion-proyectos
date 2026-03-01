package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.domain.model.Notificacion;
import ec.smartgob.gproyectos.dto.mapper.NotificacionMapper;
import ec.smartgob.gproyectos.dto.response.NotificacionResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.repository.NotificacionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificacionService {

    private final NotificacionRepository notificacionRepo;
    private final NotificacionMapper mapper;

    @Transactional(readOnly = true)
    public PageResponse<NotificacionResponse> listar(UUID destinatarioId, Pageable pageable) {
        return PageResponse.of(
                notificacionRepo.findByDestinatarioId(destinatarioId, pageable),
                mapper::toResponse);
    }

    @Transactional(readOnly = true)
    public List<NotificacionResponse> noLeidas(UUID destinatarioId) {
        return notificacionRepo.findNoLeidasByDestinatarioId(destinatarioId).stream()
                .map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public long contarNoLeidas(UUID destinatarioId) {
        return notificacionRepo.countByDestinatarioIdAndLeidoFalse(destinatarioId);
    }

    @Transactional
    public void crearNotificacion(UUID destinatarioId, String tipo, String referenciaTipo,
                                   UUID referenciaId, String titulo, String mensaje, String urlAccion) {
        // Evitar duplicados
        if (notificacionRepo.existsByDestinatarioIdAndTipoAndReferenciaId(destinatarioId, tipo, referenciaId)) {
            return;
        }

        Notificacion notif = Notificacion.builder()
                .destinatario(new Colaborador(destinatarioId))
                .tipo(tipo)
                .referenciaTipo(referenciaTipo)
                .referenciaId(referenciaId)
                .titulo(titulo)
                .mensaje(mensaje)
                .leido(false)
                .urlAccion(urlAccion)
                .createdAt(OffsetDateTime.now())
                .build();

        notificacionRepo.save(notif);
        log.debug("Notificación creada: {} para colaborador {}", tipo, destinatarioId);
    }

    @Transactional
    public void marcarLeida(UUID id, UUID destinatarioId) {
        notificacionRepo.marcarLeida(id, destinatarioId);
    }

    @Transactional
    public void marcarTodasLeidas(UUID destinatarioId) {
        notificacionRepo.marcarTodasLeidas(destinatarioId);
    }

    @Transactional
    public int limpiarAntiguas(int diasRetener) {
        OffsetDateTime limite = OffsetDateTime.now().minusDays(diasRetener);
        return notificacionRepo.eliminarLeidasAntiguas(limite);
    }
}
