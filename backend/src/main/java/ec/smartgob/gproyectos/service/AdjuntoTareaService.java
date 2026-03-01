package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.AdjuntoTarea;
import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.domain.model.Tarea;
import ec.smartgob.gproyectos.dto.mapper.AdjuntoMapper;
import ec.smartgob.gproyectos.dto.response.AdjuntoResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.repository.AdjuntoTareaRepository;
import ec.smartgob.gproyectos.repository.TareaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AdjuntoTareaService {

    private final AdjuntoTareaRepository adjuntoRepo;
    private final TareaRepository tareaRepo;
    private final AdjuntoMapper mapper;

    @Value("${app.uploads.path:./uploads}")
    private String uploadsPath;

    @Value("${app.uploads.max-size-mb:10}")
    private int maxSizeMb;

    @Transactional(readOnly = true)
    public List<AdjuntoResponse> listarPorTarea(UUID tareaId) {
        return adjuntoRepo.findByTareaIdOrdenado(tareaId).stream()
                .map(mapper::toResponse).toList();
    }

    @Transactional
    public AdjuntoResponse subir(UUID tareaId, MultipartFile file, UUID subidoPorId) {
        Tarea tarea = tareaRepo.findById(tareaId)
                .orElseThrow(() -> new ResourceNotFoundException("Tarea", tareaId.toString()));

        if (file.getSize() > (long) maxSizeMb * 1024 * 1024) {
            throw new BusinessException("Archivo excede el tamaño máximo de " + maxSizeMb + " MB");
        }

        String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();
        Path targetDir = Paths.get(uploadsPath, tarea.getContrato().getId().toString(), tareaId.toString());
        Path targetPath = targetDir.resolve(filename);

        try {
            Files.createDirectories(targetDir);
            file.transferTo(targetPath.toFile());
        } catch (IOException e) {
            log.error("Error guardando archivo: {}", e.getMessage());
            throw new BusinessException("Error al guardar el archivo");
        }

        AdjuntoTarea adjunto = AdjuntoTarea.builder()
                .tarea(tarea)
                .nombreArchivo(file.getOriginalFilename())
                .rutaArchivo(targetPath.toString())
                .tipoMime(file.getContentType())
                .tamanoBytes(file.getSize())
                .subidoPor(new Colaborador(subidoPorId))
                .createdAt(OffsetDateTime.now())
                .build();

        return mapper.toResponse(adjuntoRepo.save(adjunto));
    }

    @Transactional
    public void eliminar(UUID adjuntoId) {
        AdjuntoTarea adjunto = adjuntoRepo.findById(adjuntoId)
                .orElseThrow(() -> new ResourceNotFoundException("Adjunto", adjuntoId.toString()));
        try {
            Files.deleteIfExists(Paths.get(adjunto.getRutaArchivo()));
        } catch (IOException e) {
            log.warn("No se pudo eliminar archivo físico: {}", adjunto.getRutaArchivo());
        }
        adjuntoRepo.delete(adjunto);
    }
}
