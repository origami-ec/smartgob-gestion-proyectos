package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.*;
import ec.smartgob.gproyectos.dto.mapper.TareaMapper;
import ec.smartgob.gproyectos.dto.request.CambiarEstadoRequest;
import ec.smartgob.gproyectos.dto.request.CrearTareaRequest;
import ec.smartgob.gproyectos.dto.response.TareaResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.exception.UnauthorizedTransitionException;
import ec.smartgob.gproyectos.repository.*;
import ec.smartgob.gproyectos.security.SmartGobUserDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.time.LocalDate;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TareaServiceTest {

    @Mock private TareaRepository tareaRepo;
    @Mock private ContratoRepository contratoRepo;
    @Mock private EquipoRepository equipoRepo;
    @Mock private ColaboradorRepository colaboradorRepo;
    @Mock private AsignacionEquipoRepository asignacionRepo;
    @Mock private HistoricoEstadoTareaRepository historicoRepo;
    @Mock private ComentarioTareaRepository comentarioRepo;
    @Mock private AdjuntoTareaRepository adjuntoRepo;
    @Mock private TransicionEstadoRepository transicionRepo;
    @Mock private TareaMapper mapper;
    @Mock private ApplicationEventPublisher eventPublisher;

    @InjectMocks private TareaService tareaService;

    private UUID tareaId, contratoId, equipoId, colaboradorId;
    private Tarea tarea;
    private SmartGobUserDetails superUser;

    @BeforeEach
    void setUp() {
        tareaId = UUID.randomUUID();
        contratoId = UUID.randomUUID();
        equipoId = UUID.randomUUID();
        colaboradorId = UUID.randomUUID();

        Contrato contrato = new Contrato();
        contrato.setId(contratoId);

        Equipo equipo = new Equipo();
        equipo.setId(equipoId);

        Colaborador colab = new Colaborador();
        colab.setId(colaboradorId);

        tarea = new Tarea();
        tarea.setId(tareaId);
        tarea.setIdTarea("T-001");
        tarea.setTitulo("Tarea de prueba");
        tarea.setEstado("ASG");
        tarea.setContrato(contrato);
        tarea.setEquipo(equipo);
        tarea.setAsignadoA(colab);
        tarea.setCreadoPor(colab);
        tarea.setPrioridad("MEDIA");
        tarea.setCategoria("DESARROLLO");
        tarea.setPorcentajeAvance(0);
        tarea.setFechaEstimadaFin(LocalDate.now().plusDays(10));

        superUser = new SmartGobUserDetails(
                colaboradorId, "admin@test.ec", "Admin", "$2a$10$x",
                true, Map.of(), Set.of(), List.of());
    }

    @Nested
    @DisplayName("obtenerPorId")
    class ObtenerTests {

        @Test
        @DisplayName("Obtiene tarea existente")
        void obtener_exito() {
            TareaResponse expected = new TareaResponse();
            expected.setId(tareaId.toString());

            when(tareaRepo.findByIdConRelaciones(tareaId)).thenReturn(Optional.of(tarea));
            when(comentarioRepo.countByTareaId(tareaId)).thenReturn(3L);
            when(adjuntoRepo.countByTareaId(tareaId)).thenReturn(1L);
            when(mapper.toResponse(tarea)).thenReturn(expected);

            TareaResponse result = tareaService.obtenerPorId(tareaId);

            assertThat(result).isNotNull();
            assertThat(result.getId()).isEqualTo(tareaId.toString());
        }

        @Test
        @DisplayName("Lanza excepción si no existe")
        void obtener_noExiste() {
            when(tareaRepo.findByIdConRelaciones(tareaId)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> tareaService.obtenerPorId(tareaId))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    @Nested
    @DisplayName("cambiarEstado")
    class CambiarEstadoTests {

        @Test
        @DisplayName("Transición válida ASG → EJE por super usuario")
        void transicionValida() {
            CambiarEstadoRequest request = new CambiarEstadoRequest();
            request.setEstadoDestino("EJE");
            request.setComentario("Iniciando ejecución");

            TareaResponse expected = new TareaResponse();
            expected.setId(tareaId.toString());

            when(tareaRepo.findByIdConRelaciones(tareaId)).thenReturn(Optional.of(tarea));
            when(transicionRepo.existeTransicion("ASG", "EJE")).thenReturn(true);
            when(transicionRepo.puedeTransicionar(eq("ASG"), eq("EJE"), any())).thenReturn(true);
            when(tareaRepo.save(any())).thenReturn(tarea);
            when(comentarioRepo.countByTareaId(tareaId)).thenReturn(0L);
            when(adjuntoRepo.countByTareaId(tareaId)).thenReturn(0L);
            when(mapper.toResponse(any())).thenReturn(expected);

            TareaResponse result = tareaService.cambiarEstado(tareaId, request, superUser);

            assertThat(result).isNotNull();
            verify(historicoRepo).save(any());
            verify(eventPublisher).publishEvent(any());
        }

        @Test
        @DisplayName("Transición inválida lanza excepción")
        void transicionInvalida() {
            CambiarEstadoRequest request = new CambiarEstadoRequest();
            request.setEstadoDestino("FIN");

            when(tareaRepo.findByIdConRelaciones(tareaId)).thenReturn(Optional.of(tarea));
            when(transicionRepo.existeTransicion("ASG", "FIN")).thenReturn(false);

            assertThatThrownBy(() -> tareaService.cambiarEstado(tareaId, request, superUser))
                    .isInstanceOf(UnauthorizedTransitionException.class);
        }
    }

    @Nested
    @DisplayName("actualizarAvance")
    class AvanceTests {

        @Test
        @DisplayName("Actualiza avance correctamente")
        void actualizarAvance_exito() {
            TareaResponse expected = new TareaResponse();
            expected.setPorcentajeAvance(75);

            when(tareaRepo.findByIdConRelaciones(tareaId)).thenReturn(Optional.of(tarea));
            when(tareaRepo.save(any())).thenReturn(tarea);
            when(comentarioRepo.countByTareaId(tareaId)).thenReturn(0L);
            when(adjuntoRepo.countByTareaId(tareaId)).thenReturn(0L);
            when(mapper.toResponse(any())).thenReturn(expected);

            TareaResponse result = tareaService.actualizarAvance(tareaId, 75, "Avanzando", superUser);

            assertThat(result.getPorcentajeAvance()).isEqualTo(75);
        }

        @Test
        @DisplayName("Rechaza avance fuera de rango")
        void actualizarAvance_fueraRango() {
            when(tareaRepo.findByIdConRelaciones(tareaId)).thenReturn(Optional.of(tarea));

            assertThatThrownBy(() -> tareaService.actualizarAvance(tareaId, 150, null, superUser))
                    .isInstanceOf(BusinessException.class);
        }
    }
}
