package ec.smartgob.gproyectos.config;

import org.activiti.engine.*;
import org.activiti.spring.ProcessEngineFactoryBean;
import org.activiti.spring.SpringProcessEngineConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.transaction.PlatformTransactionManager;

import javax.sql.DataSource;
import java.io.IOException;

@Configuration
public class ActivitiConfig {

    @Bean
    public SpringProcessEngineConfiguration processEngineConfiguration(
            DataSource dataSource, PlatformTransactionManager txManager) throws IOException {

        SpringProcessEngineConfiguration config = new SpringProcessEngineConfiguration();
        config.setDataSource(dataSource);
        config.setTransactionManager(txManager);
        config.setDatabaseSchemaUpdate("true");
        config.setHistoryLevel(org.activiti.engine.impl.history.HistoryLevel.FULL);
        config.setAsyncExecutorActivate(true);

        Resource[] bpmn = new PathMatchingResourcePatternResolver()
                .getResources("classpath:/processes/*.bpmn20.xml");
        config.setDeploymentResources(bpmn);

        return config;
    }

    @Bean
    public ProcessEngineFactoryBean processEngine(SpringProcessEngineConfiguration config) {
        ProcessEngineFactoryBean factory = new ProcessEngineFactoryBean();
        factory.setProcessEngineConfiguration(config);
        return factory;
    }

    @Bean public RuntimeService runtimeService(ProcessEngine pe) { return pe.getRuntimeService(); }
    @Bean public TaskService taskService(ProcessEngine pe) { return pe.getTaskService(); }
    @Bean public HistoryService historyService(ProcessEngine pe) { return pe.getHistoryService(); }
    @Bean public RepositoryService repositoryService(ProcessEngine pe) { return pe.getRepositoryService(); }
}
