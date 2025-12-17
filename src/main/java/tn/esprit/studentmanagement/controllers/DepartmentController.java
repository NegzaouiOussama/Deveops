package tn.esprit.studentmanagement.controllers;

import lombok.AllArgsConstructor;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.services.IDepartmentService;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;

@RestController
@RequestMapping("/Department")
@CrossOrigin(origins = "http://localhost:4200")
@AllArgsConstructor
public class DepartmentController {
    private IDepartmentService departmentService;

    @GetMapping("/getAllDepartment")
    public ResponseEntity<?> getAllDepartment(
            @RequestHeader(value = "Accept", required = false) String accept,
            @RequestParam(value = "format", required = false) String format) {
        
        // Si format=json est explicitement demandé, retourner JSON
        if ("json".equalsIgnoreCase(format)) {
            return ResponseEntity.ok(departmentService.getAllDepartments());
        }
        
        // Si c'est une requête de navigateur (contient text/html ou pas d'Accept spécifique)
        // Retourner la page HTML
        if (accept == null || accept.contains("text/html") || accept.equals("*/*")) {
            try {
                Resource resource = new ClassPathResource("static/departments.html");
                String htmlContent = new String(resource.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
                
                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.TEXT_HTML);
                headers.setCacheControl("no-cache");
                
                return ResponseEntity.ok()
                        .headers(headers)
                        .body(htmlContent);
            } catch (IOException e) {
                // Si le fichier HTML n'existe pas, retourner JSON
                return ResponseEntity.ok(departmentService.getAllDepartments());
            }
        }
        
        // Pour les appels API explicites (Accept: application/json), retourner JSON
        return ResponseEntity.ok(departmentService.getAllDepartments());
    }

    @GetMapping("/getDepartment/{id}")
    public Department getDepartment(@PathVariable Long id) { return departmentService.getDepartmentById(id); }

    @PostMapping("/createDepartment")
    public Department createDepartment(@RequestBody Department department) { return departmentService.saveDepartment(department); }

    @PutMapping("/updateDepartment")
    public Department updateDepartment(@RequestBody Department department) {
        return departmentService.saveDepartment(department);
    }

    @DeleteMapping("/deleteDepartment/{id}")
    public void deleteDepartment(@PathVariable Long id) {
        departmentService.deleteDepartment(id);
    }
}
