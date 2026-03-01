package ec.smartgob.gproyectos.security;

public final class RoleConstants {
    private RoleConstants() {}

    public static final String SUPER_USUARIO = "SUPER_USUARIO";
    public static final String LIDER         = "LDR";
    public static final String ADMINISTRADOR = "ADM";
    public static final String DESARROLLADOR = "DEV";
    public static final String TESTER        = "TST";
    public static final String DOCUMENTADOR  = "DOC";

    public static boolean esRolGestion(String rol) {
        return LIDER.equals(rol) || ADMINISTRADOR.equals(rol);
    }
    public static boolean esRolEjecucion(String rol) {
        return DESARROLLADOR.equals(rol) || DOCUMENTADOR.equals(rol);
    }
}
