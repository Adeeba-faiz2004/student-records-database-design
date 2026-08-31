-- Create the database
DROP DATABASE IF EXISTS bise_results;
CREATE DATABASE bise_results;
USE bise_results;

-- ============================================
-- TABLE 1: STUDENTS
-- Stores main student information
-- ============================================
CREATE TABLE students (
    roll_number VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    student_type VARCHAR(20),
    exam_name VARCHAR(100),
    grand_total INT,
    status VARCHAR(50),
    form_id VARCHAR(30),
    INDEX idx_name (name),
    INDEX idx_status (status),
    INDEX idx_student_type (student_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABLE 2: SUBJECTS
-- Stores subject-wise marks for each student
-- ============================================
CREATE TABLE subjects (
    subject_id INT AUTO_INCREMENT PRIMARY KEY,
    roll_number VARCHAR(20) NOT NULL,
    subject_name VARCHAR(100) NOT NULL,
    theory_1 INT,
    theory_2 INT,
    practical INT,
    total INT,
    percentile DECIMAL(5,2),
    grade VARCHAR(5),
    remarks VARCHAR(50),
    FOREIGN KEY (roll_number) REFERENCES students(roll_number) ON DELETE CASCADE,
    INDEX idx_subject_name (subject_name),
    INDEX idx_grade (grade),
    INDEX idx_remarks (remarks)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================

-- CREATE VIEWS FOR COMMON QUERIES
-- ============================================


CREATE VIEW student_summary AS
SELECT 
    s.roll_number,
    s.name,
    s.student_type,
    s.grand_total,
    s.status,
    COUNT(sub.subject_id) as total_subjects,
    COUNT(CASE WHEN sub.remarks = 'Pass' THEN 1 END) as passed_subjects,
    COUNT(CASE WHEN sub.remarks LIKE '%Fail%' THEN 1 END) as failed_subjects
FROM students s
LEFT JOIN subjects sub ON s.roll_number = sub.roll_number
GROUP BY s.roll_number, s.name, s.student_type, s.grand_total, s.status;

-- View 2: Subject-wise Statistics
CREATE VIEW subject_statistics AS
SELECT 
    subject_name,
    COUNT(*) as total_students,
    ROUND(AVG(total), 2) as average_marks,
    MAX(total) as highest_marks,
    MIN(total) as lowest_marks,
    COUNT(CASE WHEN remarks = 'Pass' THEN 1 END) as passed_count,
    COUNT(CASE WHEN remarks LIKE '%Fail%' THEN 1 END) as failed_count,
    ROUND(COUNT(CASE WHEN remarks = 'Pass' THEN 1 END) * 100.0 / COUNT(*), 2) as pass_percentage
FROM subjects
GROUP BY subject_name;

-- View 3: Grade Distribution
CREATE VIEW grade_distribution AS
SELECT 
    subject_name,
    grade,
    COUNT(*) as student_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY subject_name), 2) as percentage
FROM subjects
WHERE grade IS NOT NULL AND grade != ''
GROUP BY subject_name, grade
ORDER BY subject_name, 
    CASE grade 
        WHEN 'A+' THEN 1 
        WHEN 'A' THEN 2 
        WHEN 'B+' THEN 3 
        WHEN 'B' THEN 4 
        WHEN 'C+' THEN 5 
        WHEN 'C' THEN 6 
        WHEN 'D+' THEN 7 
        WHEN 'D' THEN 8 
        WHEN 'E' THEN 9 
        ELSE 10 
    END;

-- View 4: Top Performers
CREATE VIEW top_performers AS
SELECT 
    roll_number,
    name,
    student_type,
    grand_total,
    status,
    RANK() OVER (ORDER BY grand_total DESC) as rank_position
FROM students
WHERE grand_total IS NOT NULL AND grand_total > 0
ORDER BY grand_total DESC;

SHOW TABLES;
SELECT 'Database schema created successfully!' as status
USE bise_results;

-- TABLE 1: EXAMS (Stores unique exam information)
CREATE TABLE IF NOT EXISTS exams (
    exam_id INT AUTO_INCREMENT PRIMARY KEY,
    exam_name VARCHAR(100) NOT NULL,
    exam_year YEAR NOT NULL,
    exam_type VARCHAR(50), 
    UNIQUE KEY unique_exam (exam_name, exam_year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- TABLE 2: SUBJECT_MASTER (Stores unique subject names)
CREATE TABLE IF NOT EXISTS subject_master (
    subject_id INT AUTO_INCREMENT PRIMARY KEY,
    subject_name VARCHAR(100) NOT NULL UNIQUE,
    subject_type VARCHAR(50),
    max_marks INT DEFAULT 200,
    has_practical BOOLEAN DEFAULT FALSE,
    INDEX idx_subject_name (subject_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- TABLE 3: STUDENT_TYPES (Stores student type classification)
CREATE TABLE IF NOT EXISTS student_types (
    type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(20) NOT NULL UNIQUE,
    description VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- TABLE 4: STATUS_TYPES (Stores exam result statuses)
CREATE TABLE IF NOT EXISTS status_types (
    status_id INT AUTO_INCREMENT PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- TABLE 5: STUDENTS_NORMALIZED (Main student table with FKs)
CREATE TABLE IF NOT EXISTS students_normalized (
    roll_number VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    student_type_id INT,
    exam_id INT,
    grand_total INT,
    status_id INT,
    form_id VARCHAR(30),
    FOREIGN KEY (student_type_id) REFERENCES student_types(type_id),
    FOREIGN KEY (exam_id) REFERENCES exams(exam_id),
    FOREIGN KEY (status_id) REFERENCES status_types(status_id),
    INDEX idx_name (name),
    INDEX idx_grand_total (grand_total)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- TABLE 6: SUBJECT_RESULTS_NORMALIZED (Subject marks with FKs)
CREATE TABLE IF NOT EXISTS subject_results_normalized (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    roll_number VARCHAR(20) NOT NULL,
    subject_id INT NOT NULL,
    theory_1 INT,
    theory_2 INT,
    practical INT,
    total INT,
    percentile DECIMAL(5,2),
    grade VARCHAR(5),
    remarks VARCHAR(50),
    FOREIGN KEY (roll_number) REFERENCES students_normalized(roll_number) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subject_master(subject_id),
    INDEX idx_subject (subject_id),
    INDEX idx_grade (grade),
    INDEX idx_remarks (remarks)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- STEP 2: POPULATE LOOKUP TABLES
-- ============================================

-- Populate EXAMS table
INSERT INTO exams (exam_name, exam_year, exam_type)
SELECT DISTINCT 
    exam_name,
    CASE 
        WHEN exam_name LIKE '%2024%' THEN 2024
        WHEN exam_name LIKE '%2023%' THEN 2023
        WHEN exam_name LIKE '%2022%' THEN 2022
        ELSE 2024
    END as exam_year,
    CASE 
        WHEN exam_name LIKE '%Annual%' THEN 'Annual'
        WHEN exam_name LIKE '%Supplementary%' THEN 'Supplementary'
        ELSE 'Annual'
    END as exam_type
FROM students
ON DUPLICATE KEY UPDATE exam_id=exam_id;

-- Populate SUBJECT_MASTER table
INSERT INTO subject_master (subject_name, subject_type, max_marks, has_practical)
SELECT DISTINCT 
    subject_name,
    CASE 
        WHEN subject_name IN ('BIOLOGY', 'PHYSICS', 'CHEMISTRY', 'COMPUTER SCIENCE') THEN 'Science with Practical'
        WHEN subject_name IN ('MATHEMATICS', 'STATISTICS', 'ECONOMICS') THEN 'Science/Commerce'
        WHEN subject_name IN ('ENGLISH', 'URDU') THEN 'Language'
        WHEN subject_name IN ('ISLAMIC EDUCATION', 'PAKISTAN STUDIES') THEN 'Compulsory'
        ELSE 'Other'
    END as subject_type,
    CASE 
        WHEN subject_name IN ('ISLAMIC EDUCATION', 'PAKISTAN STUDIES') THEN 50
        ELSE 200
    END as max_marks,
    CASE 
        WHEN subject_name IN ('BIOLOGY', 'PHYSICS', 'CHEMISTRY', 'COMPUTER SCIENCE') THEN TRUE
        ELSE FALSE
    END as has_practical
FROM subjects
ON DUPLICATE KEY UPDATE subject_id=subject_id;

-- Populate STUDENT_TYPES table
INSERT INTO student_types (type_name, description) VALUES
('REGULAR', 'Regular enrolled students'),
('PRIVATE', 'Private/External candidates')
ON DUPLICATE KEY UPDATE type_id=type_id;

-- Populate STATUS_TYPES table
INSERT INTO status_types (status_name, description) VALUES
('PASS', 'Passed all subjects'),
('RE-APPEAR', 'Must re-appear in failed subjects'),
('RE-APPEAR IN FAILED PAPER(S)', 'Must re-appear in specific failed papers'),
('IMPROVED', 'Re-appeared to improve marks'),
('MUST APPEAR IN FULL SUBJECTS', 'Must appear in all subjects again')
ON DUPLICATE KEY UPDATE status_id=status_id;

-- ============================================
-- STEP 3: MIGRATE DATA TO NORMALIZED TABLES
-- ============================================

-- Migrate STUDENTS data
INSERT INTO students_normalized (roll_number, name, student_type_id, exam_id, grand_total, status_id, form_id)
SELECT 
    s.roll_number,
    s.name,
    st.type_id,
    e.exam_id,
    s.grand_total,
    stat.status_id,
    s.form_id
FROM students s
LEFT JOIN student_types st ON s.student_type = st.type_name
LEFT JOIN exams e ON s.exam_name = e.exam_name
LEFT JOIN status_types stat ON s.status = stat.status_name;

-- Migrate SUBJECTS data
INSERT INTO subject_results_normalized (roll_number, subject_id, theory_1, theory_2, practical, total, percentile, grade, remarks)
SELECT 
    sub.roll_number,
    sm.subject_id,
    sub.theory_1,
    sub.theory_2,
    sub.practical,
    sub.total,
    sub.percentile,
    sub.grade,
    sub.remarks
FROM subjects sub
INNER JOIN subject_master sm ON sub.subject_name = sm.subject_name;

-- ============================================
-- STEP 4: CREATE VIEWS FOR EASY QUERYING
-- ============================================

-- View 1: Complete Student Information (Denormalized for easy querying)
CREATE OR REPLACE VIEW vw_student_complete AS
SELECT 
    sn.roll_number,
    sn.name,
    st.type_name as student_type,
    e.exam_name,
    e.exam_year,
    sn.grand_total,
    stat.status_name as status,
    sn.form_id
FROM students_normalized sn
LEFT JOIN student_types st ON sn.student_type_id = st.type_id
LEFT JOIN exams e ON sn.exam_id = e.exam_id
LEFT JOIN status_types stat ON sn.status_id = stat.status_id;

-- View 2: Complete Subject Results (Denormalized)
CREATE OR REPLACE VIEW vw_subject_results_complete AS
SELECT 
    srn.result_id,
    srn.roll_number,
    sn.name as student_name,
    sm.subject_name,
    sm.subject_type,
    srn.theory_1,
    srn.theory_2,
    srn.practical,
    srn.total,
    srn.percentile,
    srn.grade,
    srn.remarks
FROM subject_results_normalized srn
INNER JOIN students_normalized sn ON srn.roll_number = sn.roll_number
INNER JOIN subject_master sm ON srn.subject_id = sm.subject_id;

-- View 3: Student Summary with Subject Count
CREATE OR REPLACE VIEW vw_student_summary AS
SELECT 
    sn.roll_number,
    sn.name,
    st.type_name as student_type,
    e.exam_year,
    sn.grand_total,
    stat.status_name as status,
    COUNT(srn.result_id) as total_subjects,
    COUNT(CASE WHEN srn.remarks = 'Pass' THEN 1 END) as passed_subjects,
    COUNT(CASE WHEN srn.remarks LIKE '%Fail%' THEN 1 END) as failed_subjects
FROM students_normalized sn
LEFT JOIN student_types st ON sn.student_type_id = st.type_id
LEFT JOIN exams e ON sn.exam_id = e.exam_id
LEFT JOIN status_types stat ON sn.status_id = stat.status_id
LEFT JOIN subject_results_normalized srn ON sn.roll_number = srn.roll_number
GROUP BY sn.roll_number, sn.name, st.type_name, e.exam_year, sn.grand_total, stat.status_name;

-- View 4: Subject-wise Performance Statistics
CREATE OR REPLACE VIEW vw_subject_statistics AS
SELECT 
    sm.subject_name,
    sm.subject_type,
    sm.max_marks,
    COUNT(*) as total_students,
    ROUND(AVG(srn.total), 2) as average_marks,
    MAX(srn.total) as highest_marks,
    MIN(srn.total) as lowest_marks,
    COUNT(CASE WHEN srn.remarks = 'Pass' THEN 1 END) as passed_count,
    COUNT(CASE WHEN srn.remarks LIKE '%Fail%' THEN 1 END) as failed_count,
    ROUND(COUNT(CASE WHEN srn.remarks = 'Pass' THEN 1 END) * 100.0 / COUNT(*), 2) as pass_percentage
FROM subject_results_normalized srn
INNER JOIN subject_master sm ON srn.subject_id = sm.subject_id
GROUP BY sm.subject_id, sm.subject_name, sm.subject_type, sm.max_marks;

-- ============================================
-- STEP 5: VERIFICATION QUERIES
-- ============================================

-- Check record counts
SELECT 'Original Students' as Table_Name, COUNT(*) as Record_Count FROM students
UNION ALL
SELECT 'Normalized Students', COUNT(*) FROM students_normalized
UNION ALL
SELECT 'Original Subjects', COUNT(*) FROM subjects
UNION ALL
SELECT 'Normalized Subject Results', COUNT(*) FROM subject_results_normalized
UNION ALL
SELECT 'Exams Master', COUNT(*) FROM exams
UNION ALL
SELECT 'Subject Master', COUNT(*) FROM subject_master
UNION ALL
SELECT 'Student Types', COUNT(*) FROM student_types
UNION ALL
SELECT 'Status Types', COUNT(*) FROM status_types;


SELECT 'Normalization complete! Database is now in 3NF.' as Status;
