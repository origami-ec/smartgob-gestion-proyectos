package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.Empresa;
import ec.smartgob.gproyectos.dto.mapper.EmpresaMapper;
import ec.smartgob.gproyectos.dto.request.CrearEmpresaRequest;
import ec.smartgob.gproyectos.dto.response.EmpresaResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.repository.EmpresaRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EmpresaServiceTest {

    @Mock private EmpresaRepository empresaRepo;
    @Mock private EmpresaMapper mapper;

    @InjectMocks private EmpresaService empresaService;

    @Test
    @DisplayName("Crear empresa con RUC único")
    void crearEmpresa_exito() {
        CrearEmpresaRequest request = new CrearEmpresaRequest();
        request.setRuc("0990000001001");
        request.setRazonSocial("TECH2GO S.A.");
        request.setTipo("CONTRATADA");

        Empresa empresa = new Empresa();
        empresa.setId(UUID.randomUUID());

        EmpresaResponse expected = new EmpresaResponse();
        expected.setRuc("0990000001001");

        when(empresaRepo.existsByRuc("0990000001001")).thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(empresa);
        when(empresaRepo.save(any())).thenReturn(empresa);
        when(mapper.toResponse(any())).thenReturn(expected);

        EmpresaResponse result = empresaService.crear(request);

        assertThat(result.getRuc()).isEqualTo("0990000001001");
        verify(empresaRepo).save(any());
    }

    @Test
    @DisplayName("Crear empresa con RUC duplicado falla")
    void crearEmpresa_rucDuplicado() {
        CrearEmpresaRequest request = new CrearEmpresaRequest();
        request.setRuc("0990000001001");

        when(empresaRepo.existsByRuc("0990000001001")).thenReturn(true);

        assertThatThrownBy(() -> empresaService.crear(request))
                .isInstanceOf(BusinessException.class);
    }
}
