package tn.esprit.studentmanagement.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI studentManagementOpenAPI() {
        Server devServer = new Server();
        devServer.setUrl("http://localhost:8089/student");
        devServer.setDescription("Serveur de développement");

        Server kubernetesServer = new Server();
        kubernetesServer.setUrl("http://192.168.49.2:30080/student");
        kubernetesServer.setDescription("Serveur Kubernetes (Minikube)");

        Contact contact = new Contact();
        contact.setEmail("contact@esprit.tn");
        contact.setName("Équipe Student Management");
        contact.setUrl("https://esprit.tn");

        License license = new License()
                .name("MIT License")
                .url("https://opensource.org/licenses/MIT");

        Info info = new Info()
                .title("Student Management API")
                .version("1.0.0")
                .contact(contact)
                .description("""
                        API REST complète pour la gestion des étudiants, départements et inscriptions.
                        
                        Cette API permet de :
                        - Gérer les départements (CRUD complet)
                        - Gérer les étudiants (CRUD complet)
                        - Gérer les inscriptions (CRUD complet)
                        - Gérer les cours
                        
                        **Technologies utilisées :**
                        - Spring Boot 3.x
                        - Spring Data JPA
                        - MySQL
                        - Swagger/OpenAPI 3
                        """)
                .termsOfService("https://esprit.tn/terms")
                .license(license);

        return new OpenAPI()
                .info(info)
                .servers(List.of(devServer, kubernetesServer));
    }
}

