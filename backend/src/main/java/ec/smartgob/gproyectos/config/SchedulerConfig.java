package ec.smartgob.gproyectos.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;

@Configuration
public class SchedulerConfig {

    @Bean
    public ThreadPoolTaskScheduler taskScheduler() {
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setPoolSize(4);
        scheduler.setThreadNamePrefix("smartgob-sla-");
        scheduler.setErrorHandler(t ->
            org.slf4j.LoggerFactory.getLogger("SLAScheduler")
                .error("Error en job: {}", t.getMessage(), t));
        return scheduler;
    }
}
