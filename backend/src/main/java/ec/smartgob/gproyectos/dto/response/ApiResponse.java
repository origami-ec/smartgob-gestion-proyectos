package ec.smartgob.gproyectos.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.*;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {
    private boolean success;
    private String message;
    private T data;
    private Object errors;

    public static <T> ApiResponse<T> ok(T data) { return ApiResponse.<T>builder().success(true).data(data).build(); }
    public static <T> ApiResponse<T> ok(T data, String msg) { return ApiResponse.<T>builder().success(true).data(data).message(msg).build(); }
    public static <T> ApiResponse<T> error(String msg) { return ApiResponse.<T>builder().success(false).message(msg).build(); }
    public static <T> ApiResponse<T> error(String msg, Object errors) { return ApiResponse.<T>builder().success(false).message(msg).errors(errors).build(); }
}
