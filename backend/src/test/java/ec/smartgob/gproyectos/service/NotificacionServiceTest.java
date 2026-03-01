package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.domain.model.Notificacion;
import ec.smartgob.gproyectos.repository.ColaboradorRepository;
import ec.smartgob.gproyectos.repository.NotificacionRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificacionServiceTest {

    @Mock private NotificacionRepository notificacionRepo;
    @Mock private ColaboradorRepository colaboradorRepo;

    @InjectMocks private NotificacionService notificacionService;

    @Test
    @DisplayName("Crear notificación sin duplicados")
    void crearNotificacion_sinDuplicado() {
        UUID destinatarioId = UUID.randomUUID();
        UUID referenciaId = UUID.randomUUID();
        Colaborador dest = new Colaborador();
        dest.setId(destinatarioId);

        when(colaboradorRepo.findById(destinatarioId)).thenReturn(Optional.of(dest));
        when(notificacionRepo.existsByDestinatarioIdAndTipoAndReferenciaId(destinatarioId, "TAREA_ASIGNADA", referenciaId))
                .thenReturn(false);

        notificacionService.crearNotificacion(destinatarioId, "TAREA_ASIGNADA", "TAREA", referenciaId,
                "Nueva tarea", "Tienes una nueva tarea", "/tareas/123");

        verify(notificacionRepo).save(any(Notificacion.class));
    }

    @Test
    @DisplayName("Deduplicar notificaciones del mismo tipo")
    void crearNotificacion_duplicadaIgnorada() {
        UUID destinatarioId = UUID.randomUUID();
        UUID referenciaId = UUID.randomUUID();

        when(notificacionRepo.existsByDestinatarioIdAndTipoAndReferenciaId(destinatarioId, "TAREA_ASIGNADA", referenciaId))
                .thenReturn(true);

        notificacionService.crearNotificacion(destinatarioId, "TAREA_ASIGNADA", "TAREA", referenciaId,
                "Nueva tarea", "Tienes una nueva tarea", "/tareas/123");

        verify(notificacionRepo, never()).save(any());
    }
}
