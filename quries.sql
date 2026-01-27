


-- Sample Queries for Student Records Database

-- 1. Get all students
SELECT * FROM students_data;

-- 2. Get all subjects for a specific student
SELECT *
FROM subjects_data
WHERE Roll_Number = 812001;

-- 3. Join student info with subjects for a specific student
SELECT 
    s.Roll_Number,
    s.Name,
    s.Student_Type,
    s.Exam_Name,
    s.Status,
    sub.Subject,
    sub.Theory_I,
    sub.Theory_II,
    sub.Practical,
    sub.Total,
    sub.Grade,
    sub.Remarks
FROM students_data s
JOIN subjects_data sub
    ON s.Roll_Number = sub.Roll_Number
WHERE s.Roll_Number = 812001;

-- 4. All students with their subjects, total, and grade
SELECT 
    s.Roll_Number,
    s.Name,
    sub.Subject,
    sub.Total,
    sub.Grade,
    sub.Remarks
FROM students_data s
JOIN subjects_data sub
    ON s.Roll_Number = sub.Roll_Number
ORDER BY s.Roll_Number;

-- 5. Students who passed
SELECT Roll_Number, Name, Grand_Total
FROM students_data
WHERE Status = 'PASS';

-- 6. Students who need to reappear
SELECT Roll_Number, Name
FROM students_data
WHERE Status = 'RE-APPEAR IN FAILED PAPER(S)';

-- 7. Check failed subjects for a student
SELECT Subject, Remarks
FROM subjects_data
WHERE Roll_Number = 812001
  AND Remarks LIKE '%Fail%';

-- 8. Calculate grand total per student
SELECT 
    Roll_Number,
    SUM(Total) AS Calculated_Grand_Total
FROM subjects_data
GROUP BY Roll_Number;

-- 9. Compare stored grand total with calculated total
SELECT 
    s.Roll_Number,
    s.Name,
    s.Grand_Total AS Stored_Total,
    SUM(sub.Total) AS Calculated_Total
FROM students_data s
JOIN subjects_data sub
    ON s.Roll_Number = sub.Roll_Number
GROUP BY s.Roll_Number, s.Name, s.Grand_Total;

-- 10. Physics subject failures
SELECT Roll_Number, Subject, Remarks
FROM subjects_data
WHERE Subject = 'PHYSICS'
  AND Remarks LIKE '%Fail%';

-- 11. Count failures per subject
SELECT 
    Subject,
    COUNT(*) AS Failure_Count
FROM subjects_data
WHERE Remarks LIKE '%Fail%'
GROUP BY Subject;

-- 12. Search student by name
SELECT *
FROM students_data
WHERE Name LIKE '%HAMZA%';

-- 13. Search subjects by grade
SELECT *
FROM subjects_data
WHERE Grade = 'C+';