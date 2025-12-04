package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.repositories.StudentRepository;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class StudentServiceTest {

    @Mock
    private StudentRepository studentRepository;

    @InjectMocks
    private StudentService studentService;

    private Student student;
    private Student student2;

    @BeforeEach
    void setUp() {
        student = new Student();
        student.setIdStudent(1L);
        student.setFirstName("John");
        student.setLastName("Doe");
        student.setEmail("john.doe@example.com");
        student.setDateOfBirth(LocalDate.of(2000, 1, 15));
        student.setAddress("123 Main St");
        student.setPhone("1234567890");

        student2 = new Student();
        student2.setIdStudent(2L);
        student2.setFirstName("Jane");
        student2.setLastName("Smith");
        student2.setEmail("jane.smith@example.com");
        student2.setDateOfBirth(LocalDate.of(2001, 5, 20));
        student2.setAddress("456 Oak Ave");
        student2.setPhone("0987654321");
    }

    @Test
    void testGetAllStudents() {
        // Given
        List<Student> students = Arrays.asList(student, student2);
        when(studentRepository.findAll()).thenReturn(students);

        // When
        List<Student> result = studentService.getAllStudents();

        // Then
        assertNotNull(result);
        assertEquals(2, result.size());
        assertEquals("John", result.get(0).getFirstName());
        assertEquals("Jane", result.get(1).getFirstName());
        verify(studentRepository, times(1)).findAll();
    }

    @Test
    void testGetStudentById_Found() {
        // Given
        Long id = 1L;
        when(studentRepository.findById(id)).thenReturn(Optional.of(student));

        // When
        Student result = studentService.getStudentById(id);

        // Then
        assertNotNull(result);
        assertEquals(id, result.getIdStudent());
        assertEquals("John", result.getFirstName());
        assertEquals("Doe", result.getLastName());
        verify(studentRepository, times(1)).findById(id);
    }

    @Test
    void testGetStudentById_NotFound() {
        // Given
        Long id = 999L;
        when(studentRepository.findById(id)).thenReturn(Optional.empty());

        // When
        Student result = studentService.getStudentById(id);

        // Then
        assertNull(result);
        verify(studentRepository, times(1)).findById(id);
    }

    @Test
    void testSaveStudent() {
        // Given
        Student newStudent = new Student();
        newStudent.setFirstName("Alice");
        newStudent.setLastName("Brown");
        newStudent.setEmail("alice.brown@example.com");
        
        Student savedStudent = new Student();
        savedStudent.setIdStudent(3L);
        savedStudent.setFirstName("Alice");
        savedStudent.setLastName("Brown");
        savedStudent.setEmail("alice.brown@example.com");
        
        when(studentRepository.save(any(Student.class))).thenReturn(savedStudent);

        // When
        Student result = studentService.saveStudent(newStudent);

        // Then
        assertNotNull(result);
        assertEquals("Alice", result.getFirstName());
        assertEquals("Brown", result.getLastName());
        verify(studentRepository, times(1)).save(newStudent);
    }

    @Test
    void testDeleteStudent() {
        // Given
        Long id = 1L;
        doNothing().when(studentRepository).deleteById(id);

        // When
        studentService.deleteStudent(id);

        // Then
        verify(studentRepository, times(1)).deleteById(id);
    }
}

