package ec.smartgob.gproyectos.repository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

@Repository
public class TransicionEstadoRepository {

    @PersistenceContext
    private EntityManager em;

    public boolean existeTransicion(String estadoOrigen, String estadoDestino) {
        Long count = (Long) em.createNativeQuery(
                "SELECT COUNT(*) FROM gestion_proyectos.param_transicion_estado WHERE estado_origen = :o AND estado_destino = :d AND activo = TRUE")
                .setParameter("o", estadoOrigen).setParameter("d", estadoDestino).getSingleResult();
        return count > 0;
    }

    public Optional<List<String>> findRolesPermitidos(String estadoOrigen, String estadoDestino) {
        @SuppressWarnings("unchecked")
        List<String> results = em.createNativeQuery(
                "SELECT roles_permitidos FROM gestion_proyectos.param_transicion_estado WHERE estado_origen = :o AND estado_destino = :d AND activo = TRUE")
                .setParameter("o", estadoOrigen).setParameter("d", estadoDestino).getResultList();
        if (results.isEmpty()) return Optional.empty();
        return Optional.of(Arrays.asList(results.get(0).split(",")));
    }

    public boolean puedeTransicionar(String estadoOrigen, String estadoDestino, String rol) {
        return findRolesPermitidos(estadoOrigen, estadoDestino)
                .map(roles -> roles.contains(rol) || roles.contains("SYSTEM")).orElse(false);
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> findTransicionesDesde(String estadoOrigen) {
        return em.createNativeQuery(
                "SELECT estado_destino, accion, roles_permitidos, descripcion FROM gestion_proyectos.param_transicion_estado WHERE estado_origen = :o AND activo = TRUE ORDER BY estado_destino")
                .setParameter("o", estadoOrigen).getResultList();
    }
}
