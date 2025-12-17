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

@RestController
@RequestMapping("/Department")
@CrossOrigin(origins = "http://localhost:4200")
@AllArgsConstructor
public class DepartmentController {
    private IDepartmentService departmentService;

    @GetMapping(value = "/getAllDepartment", produces = {MediaType.TEXT_HTML_VALUE, MediaType.APPLICATION_JSON_VALUE})
    public ResponseEntity<?> getAllDepartment(
            @RequestHeader(value = "Accept", required = false) String accept,
            @RequestParam(value = "format", required = false) String format,
            @RequestParam(value = "json", required = false) String jsonParam) {
        
        // Si format=json ou ?json est explicitement demandé, retourner JSON
        if ("json".equalsIgnoreCase(format) || jsonParam != null) {
            return ResponseEntity.ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(departmentService.getAllDepartments());
        }
        
        // Par défaut, retourner HTML pour les navigateurs
        // Si Accept contient explicitement application/json ET pas text/html, retourner JSON
        boolean explicitlyWantsJson = accept != null && 
            accept.contains("application/json") && 
            !accept.contains("text/html");
        
        if (!explicitlyWantsJson) {
            // Retourner HTML par défaut (pour navigateurs)
            try {
                Resource resource = new ClassPathResource("static/departments.html");
                String htmlContent = new String(resource.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
                
                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.TEXT_HTML);
                headers.setCacheControl("no-cache, no-store, must-revalidate");
                
                return ResponseEntity.ok()
                        .headers(headers)
                        .body(htmlContent);
            } catch (IOException e) {
                // Si le fichier HTML n'existe pas, retourner JSON
                return ResponseEntity.ok()
                        .contentType(MediaType.APPLICATION_JSON)
                        .body(departmentService.getAllDepartments());
            }
        }
        
        // Pour les appels API explicites (Accept: application/json uniquement), retourner JSON
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .body(departmentService.getAllDepartments());
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
