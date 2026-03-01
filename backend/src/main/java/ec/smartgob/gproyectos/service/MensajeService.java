package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.domain.model.Contrato;
import ec.smartgob.gproyectos.domain.model.Equipo;
import ec.smartgob.gproyectos.domain.model.Mensaje;
import ec.smartgob.gproyectos.dto.mapper.MensajeMapper;
import ec.smartgob.gproyectos.dto.request.EnviarMensajeRequest;
import ec.smartgob.gproyectos.dto.response.MensajeResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.repository.MensajeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MensajeService {

    private final MensajeRepository mensajeRepo;
    private final MensajeMapper mapper;

    @Transactional(readOnly = true)
    public PageResponse<MensajeResponse> bandejaEntrada(UUID destinatarioId, Pageable pageable) {
        return PageResponse.of(
                mensajeRepo.findBandejaEntrada(destinatarioId, pageable),
                mapper::toResponse);
    }

    @Transactional(readOnly = true)
    public PageResponse<MensajeResponse> mensajesEquipo(UUID equipoId, Pageable pageable) {
        return PageResponse.of(
                mensajeRepo.findByEquipoId(equipoId, pageable),
                mapper::toResponse);
    }

    @Transactional(readOnly = true)
    public PageResponse<MensajeResponse> mensajesContrato(UUID contratoId, Pageable pageable) {
        return PageResponse.of(
                mensajeRepo.findByContratoId(contratoId, pageable),
                mapper::toResponse);
    }

    @Transactional(readOnly = true)
    public List<MensajeResponse> conversacionDirecta(UUID usuarioA, UUID usuarioB) {
        return mensajeRepo.findConversacionDirecta(usuarioA, usuarioB).stream()
                .map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public long contarNoLeidos(UUID destinatarioId) {
        return mensajeRepo.countByDestinatarioIdAndLeidoFalse(destinatarioId);
    }

    @Transactional
    public MensajeResponse enviar(EnviarMensajeRequest request, UUID remitenteId) {
        if ("DIRECTO".equals(request.getTipo()) && request.getDestinatarioId() == null) {
            throw new BusinessException("Mensaje directo requiere destinatario");
        }
        if ("EQUIPO".equals(request.getTipo()) && request.getEquipoId() == null) {
            throw new BusinessException("Mensaje de equipo requiere equipo");
        }

        Mensaje mensaje = Mensaje.builder()
                .remitente(new Colaborador(remitenteId))
                .destinatario(request.getDestinatarioId() != null ? new Colaborador(request.getDestinatarioId()) : null)
                .equipo(request.getEquipoId() != null ? new Equipo(request.getEquipoId()) : null)
                .contrato(request.getContratoId() != null ? new Contrato(request.getContratoId()) : null)
                .asunto(request.getAsunto())
                .contenido(request.getContenido())
                .tipo(request.getTipo())
                .leido(false)
                .createdAt(OffsetDateTime.now())
                .build();

        return mapper.toResponse(mensajeRepo.save(mensaje));
    }

    @Transactional
    public void marcarLeido(UUID mensajeId, UUID destinatarioId) {
        mensajeRepo.marcarLeido(mensajeId, destinatarioId);
    }

    @Transactional
    public void marcarTodosLeidos(UUID destinatarioId) {
        mensajeRepo.marcarTodosLeidos(destinatarioId);
    }
}
