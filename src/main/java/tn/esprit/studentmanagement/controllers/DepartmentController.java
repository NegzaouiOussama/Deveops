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

    @GetMapping("/getAllDepartment")
    public ResponseEntity<?> getAllDepartment(
            @RequestHeader(value = "Accept", required = false) String accept,
            @RequestParam(value = "format", required = false) String format) {
        
        // Si format=html est explicitement demandé, retourner HTML
        if ("html".equalsIgnoreCase(format)) {
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
        
        // Par défaut, retourner JSON pour les appels API
        // Uniquement si Accept contient explicitement "text/html" et pas "application/json"
        boolean wantsHtmlOnly = accept != null && 
            accept.contains("text/html") && 
            !accept.contains("application/json") &&
            !accept.contains("*/*");
        
        if (wantsHtmlOnly) {
            // Retourner HTML uniquement si explicitement demandé
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
        
        // Par défaut, retourner JSON pour les appels API
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
