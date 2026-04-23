-- Team 11 (EDS6343 26619 MAIN - Database Management Tools for Engineers)
-- Project Phase 3: SQL Implementation and Query Design
-- Project: Campus Tutoring & Office Hours Booking Platform (Tutor Hub)

CREATE DATABASE TutorHub;
USE TutorHub;

-- 1. Department
CREATE TABLE Department (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    department_code VARCHAR(20) NOT NULL UNIQUE
);

-- 2. Role
CREATE TABLE Role (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(30) NOT NULL UNIQUE,
    CONSTRAINT chk_role_name
        CHECK (role_name IN ('Student', 'Tutor', 'TA', 'Instructor'))
);

-- 3. User
CREATE TABLE User (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    role_id INT NOT NULL,
    department_id INT NOT NULL,
    university_id VARCHAR(30) NOT NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_user_role
        FOREIGN KEY (role_id) REFERENCES Role(role_id),
    CONSTRAINT fk_user_department
        FOREIGN KEY (department_id) REFERENCES Department(department_id)
);

-- 4. Course
CREATE TABLE Course (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    course_code VARCHAR(20) NOT NULL,
    course_title VARCHAR(100) NOT NULL,
    course_description VARCHAR(255),
    credits INT,
    CONSTRAINT fk_course_department
        FOREIGN KEY (department_id) REFERENCES Department(department_id),
    CONSTRAINT uq_course UNIQUE (department_id, course_code)
);

-- 5. Topic
CREATE TABLE Topic (
    topic_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id INT NOT NULL,
    topic_name VARCHAR(100) NOT NULL,
    topic_description VARCHAR(255),
    CONSTRAINT fk_topic_course
        FOREIGN KEY (course_id) REFERENCES Course(course_id),
    CONSTRAINT uq_topic UNIQUE (course_id, topic_name)
);

-- 6. Tutor_Course
CREATE TABLE Tutor_Course (
    tutor_course_id INT AUTO_INCREMENT PRIMARY KEY,
    tutor_user_id INT NOT NULL,
    course_id INT NOT NULL,
    assigned_since DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_tutorcourse_user
        FOREIGN KEY (tutor_user_id) REFERENCES User(user_id),
    CONSTRAINT fk_tutorcourse_course
        FOREIGN KEY (course_id) REFERENCES Course(course_id),
    CONSTRAINT uq_tutor_course UNIQUE (tutor_user_id, course_id)
);

-- 7. Availability_Slot
CREATE TABLE Availability_Slot (
    slot_id INT AUTO_INCREMENT PRIMARY KEY,
    provider_user_id INT NOT NULL,
    course_id INT NOT NULL,
    slot_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    mode VARCHAR(20) NOT NULL,
    location VARCHAR(150),
    meeting_link VARCHAR(255),
    slot_status VARCHAR(20) NOT NULL DEFAULT 'Available',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_slot_provider
        FOREIGN KEY (provider_user_id) REFERENCES User(user_id),
    CONSTRAINT fk_slot_course
        FOREIGN KEY (course_id) REFERENCES Course(course_id),
    CONSTRAINT chk_slot_time
        CHECK (start_time < end_time),
    CONSTRAINT chk_slot_mode
        CHECK (mode IN ('In-Person', 'Online')),
    CONSTRAINT chk_slot_status
        CHECK (slot_status IN ('Available', 'Booked', 'Cancelled'))
);

-- 8. Booking
CREATE TABLE Booking (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    slot_id INT NOT NULL UNIQUE,
    student_user_id INT NOT NULL,
    course_id INT NOT NULL,
    topic_id INT NULL,
    booking_status VARCHAR(20) NOT NULL,
    booking_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cancellation_reason VARCHAR(255),
    cancelled_at DATETIME,
    CONSTRAINT fk_booking_slot
        FOREIGN KEY (slot_id) REFERENCES Availability_Slot(slot_id),
    CONSTRAINT fk_booking_student
        FOREIGN KEY (student_user_id) REFERENCES User(user_id),
    CONSTRAINT fk_booking_course
        FOREIGN KEY (course_id) REFERENCES Course(course_id),
    CONSTRAINT fk_booking_topic
        FOREIGN KEY (topic_id) REFERENCES Topic(topic_id),
    CONSTRAINT chk_booking_status
        CHECK (booking_status IN ('Pending', 'Confirmed', 'Cancelled', 'Completed', 'No-Show'))
);

-- 9. Session_Record
CREATE TABLE Session_Record (
    session_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL UNIQUE,
    actual_start_time DATETIME,
    actual_end_time DATETIME,
    duration_minutes INT,
    attendance_status VARCHAR(30) NOT NULL,
    session_status VARCHAR(20) NOT NULL,
    session_notes VARCHAR(500),
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_session_booking
        FOREIGN KEY (booking_id) REFERENCES Booking(booking_id),
    CONSTRAINT chk_attendance_status
        CHECK (attendance_status IN ('Attended', 'Missed by Student', 'Missed by Tutor')),
    CONSTRAINT chk_session_status
        CHECK (session_status IN ('Completed', 'Cancelled', 'No-Show'))
);

-- 10. Feedback
CREATE TABLE Feedback (
    feedback_id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT NOT NULL UNIQUE,
    student_user_id INT NOT NULL,
    rating INT NOT NULL,
    comments VARCHAR(500),
    submitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_feedback_session
        FOREIGN KEY (session_id) REFERENCES Session_Record(session_id),
    CONSTRAINT fk_feedback_student
        FOREIGN KEY (student_user_id) REFERENCES User(user_id),
    CONSTRAINT chk_rating
        CHECK (rating BETWEEN 1 AND 5)
);
-- =========================
-- Step 2: Insert data
-- =========================
USE TutorHub;

-- 1. Department

INSERT INTO Department (department_name, department_code) VALUES
('Computer Science', 'CS'),
('Mathematics', 'MATH'),
('Electrical Engineering', 'ECE'),
('Physics', 'PHYS');

-- 2. Role
INSERT INTO Role (role_name) VALUES
('Student'),
('Tutor'),
('TA'),
('Instructor');

-- 3. User
INSERT INTO User (first_name, last_name, email, phone, role_id, department_id, university_id, is_active) VALUES
('Aarav', 'Sharma', 'aarav.sharma@uh.edu', '7135551001', 1, 1, 'UH1001', TRUE),
('Maya', 'Patel', 'maya.patel@uh.edu', '7135551002', 1, 2, 'UH1002', TRUE),
('Rohan', 'Reddy', 'rohan.reddy@uh.edu', '7135551003', 1, 3, 'UH1003', TRUE),
('Anika', 'Verma', 'anika.verma@uh.edu', '7135551004', 1, 1, 'UH1004', TRUE),
('David', 'Lee', 'david.lee@uh.edu', '7135552001', 2, 1, 'UH2001', TRUE),
('Sophia', 'Nguyen', 'sophia.nguyen@uh.edu', '7135552002', 2, 2, 'UH2002', TRUE),
('Ethan', 'Brown', 'ethan.brown@uh.edu', '7135553001', 3, 3, 'UH3001', TRUE),
('Drake', 'Wilson', 'drake.wilson@uh.edu', '7135554001', 4, 1, 'UH4001', TRUE),
('Priya', 'Nair', 'priya.nair@uh.edu', '7135553002', 3, 2, 'UH3002', TRUE),
('Laura', 'Garcia', 'laura.garcia@uh.edu', '7135554002', 4, 4, 'UH4002', TRUE);

-- 4. Course
INSERT INTO Course (department_id, course_code, course_title, course_description, credits) VALUES
(1, 'COSC 1437', 'Introduction to Programming', 'Programming fundamentals using problem-solving techniques', 3),
(1, 'COSC 2436', 'Programming and Data Structures', 'Intermediate programming and data structures', 4),
(2, 'MATH 2413', 'Calculus I', 'Differential calculus and applications', 4),
(3, 'ECE 2201', 'Circuit Analysis I', 'Basic electric circuit analysis', 3),
(4, 'PHYS 2325', 'University Physics I', 'Mechanics, motion, and force', 4);

-- 5. Topic
INSERT INTO Topic (course_id, topic_name, topic_description) VALUES
(1, 'Variables and Data Types', 'Basics of variables, constants, and data types'),
(1, 'Loops and Conditionals', 'Decision-making and iteration'),
(2, 'Linked Lists', 'Singly and doubly linked lists'),
(2, 'Stacks and Queues', 'Linear data structures and operations'),
(3, 'Limits and Derivatives', 'Foundations of differential calculus'),
(3, 'Applications of Derivatives', 'Optimization and curve sketching'),
(4, 'Ohms Law', 'Voltage, current, and resistance relationships'),
(4, 'Kirchhoff Laws', 'KCL and KVL circuit analysis'),
(5, 'Newtonian Mechanics', 'Laws of motion and applications'),
(5, 'Work and Energy', 'Energy conservation and work-energy theorem');

-- 6. Tutor_Course
INSERT INTO Tutor_Course (tutor_user_id, course_id, assigned_since, is_active) VALUES
(5, 1, '2026-01-10', TRUE),
(5, 2, '2026-01-10', TRUE),
(6, 3, '2026-01-12', TRUE),
(7, 4, '2026-01-15', TRUE),
(8, 2, '2026-01-20', TRUE),
(9, 3, '2026-01-18', TRUE),
(10, 5, '2026-01-22', TRUE);

-- 7. Availability_Slot
INSERT INTO Availability_Slot (provider_user_id, course_id, slot_date, start_time, end_time, mode, location, meeting_link, slot_status) VALUES
(5, 1, '2026-04-10', '10:00:00', '11:00:00', 'In-Person', 'CASA Room 101', NULL, 'Booked'),
(5, 2, '2026-04-10', '14:00:00', '15:00:00', 'Online', NULL, 'https://meet.google.com/ds1', 'Booked'),
(6, 3, '2026-04-11', '09:00:00', '10:00:00', 'In-Person', 'Math Center 12', NULL, 'Booked'),
(7, 4, '2026-04-11', '13:00:00', '14:00:00', 'Online', NULL, 'https://meet.google.com/ece1', 'Booked'),
(8, 2, '2026-04-12', '11:00:00', '12:00:00', 'In-Person', 'ENGR 201', NULL, 'Available'),
(9, 3, '2026-04-12', '15:00:00', '16:00:00', 'Online', NULL, 'https://meet.google.com/math2', 'Booked'),
(10, 5, '2026-04-13', '10:00:00', '11:00:00', 'In-Person', 'Physics Lab 2', NULL, 'Booked'),
(5, 1, '2026-04-14', '12:00:00', '13:00:00', 'Online', NULL, 'https://meet.google.com/cosc1', 'Cancelled');

-- 8. Booking
INSERT INTO Booking (slot_id, student_user_id, course_id, topic_id, booking_status, cancellation_reason, cancelled_at) VALUES
(1, 1, 1, 1, 'Completed', NULL, NULL),
(2, 2, 2, 3, 'Completed', NULL, NULL),
(3, 4, 3, 5, 'Completed', NULL, NULL),
(4, 3, 4, 8, 'No-Show', NULL, NULL),
(6, 1, 3, 6, 'Completed', NULL, NULL),
(7, 2, 5, 9, 'Completed', NULL, NULL),
(8, 4, 1, 2, 'Cancelled', 'Tutor unavailable', '2026-04-13 18:00:00');

UPDATE Booking SET booking_timestamp = '2026-04-10 10:00:00' WHERE booking_id = 1;
UPDATE Booking SET booking_timestamp = '2026-04-11 11:00:00' WHERE booking_id = 2;
UPDATE Booking SET booking_timestamp = '2026-04-12 12:00:00' WHERE booking_id = 3;
UPDATE Booking SET booking_timestamp = '2026-04-13 13:00:00' WHERE booking_id = 4;
UPDATE Booking SET booking_timestamp = '2026-04-14 14:00:00' WHERE booking_id = 5;
UPDATE Booking SET booking_timestamp = '2026-04-15 15:00:00' WHERE booking_id = 6;
UPDATE Booking SET booking_timestamp = '2026-04-16 16:00:00' WHERE booking_id = 7;
-- 9. Session_Record
INSERT INTO Session_Record (booking_id, actual_start_time, actual_end_time, duration_minutes, attendance_status, session_status, session_notes) VALUES
(1, '2026-04-10 10:00:00', '2026-04-10 10:55:00', 55, 'Attended', 'Completed', 'Reviewed variables and basic syntax'),
(2, '2026-04-10 14:00:00', '2026-04-10 14:50:00', 50, 'Attended', 'Completed', 'Worked through linked list examples'),
(3, '2026-04-11 09:00:00', '2026-04-11 09:45:00', 45, 'Attended', 'Completed', 'Discussed derivative rules and examples'),
(4, '2026-04-11 13:00:00', '2026-04-11 13:15:00', 15, 'Missed by Student', 'No-Show', 'Student did not join online session'),
(5, '2026-04-12 15:00:00', '2026-04-12 15:50:00', 50, 'Attended', 'Completed', 'Covered optimization problems'),
(6, '2026-04-13 10:00:00', '2026-04-13 10:55:00', 55, 'Attended', 'Completed', 'Explained Newtonian mechanics concepts'),
(7, NULL, NULL, NULL, 'Missed by Tutor', 'Cancelled', 'Session cancelled before start');

-- 10. Feedback
INSERT INTO Feedback (session_id, student_user_id, rating, comments) VALUES
(1, 1, 5, 'Very clear explanation and helpful examples.'),
(2, 2, 4, 'Good session, but I wanted a few more coding examples.'),
(3, 4, 5, 'Excellent help with calculus concepts.'),
(5, 1, 4, 'Helpful session and good pace.'),
(6, 2, 5, 'The physics concepts were explained really well.');


SELECT * FROM Department;
SELECT * FROM User;
SELECT * FROM Booking;
SELECT * FROM Session_Record;
SELECT * FROM Feedback;

-- =========================
-- Step 3: Query Pack
-- =========================
-- Here is the first set: 6 basic queries
-- Q1: Display all users along with their assigned roles and departments
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    r.role_name,
    d.department_name
FROM User u
JOIN Role r ON u.role_id = r.role_id
JOIN Department d ON u.department_id = d.department_id;

-- Q2: Display all currently available slots with provider and course information
SELECT 
    a.slot_id,
    u.first_name AS provider_first_name,
    u.last_name AS provider_last_name,
    c.course_code,
    c.course_title,
    a.slot_date,
    a.start_time,
    a.end_time,
    a.mode,
    a.slot_status
FROM Availability_Slot a
JOIN User u ON a.provider_user_id = u.user_id
JOIN Course c ON a.course_id = c.course_id
WHERE a.slot_status = 'Available';

-- Q3: Display all bookings with student names and booking status
SELECT 
    b.booking_id,
    u.first_name AS student_first_name,
    u.last_name AS student_last_name,
    c.course_code,
    b.booking_status,
    b.booking_timestamp
FROM Booking b
JOIN User u ON b.student_user_id = u.user_id
JOIN Course c ON b.course_id = c.course_id;

-- Q4: Display all completed session records with student names
SELECT 
    s.session_id,
    b.booking_id,
    u.first_name AS student_first_name,
    u.last_name AS student_last_name,
    s.session_status,
    s.attendance_status,
    s.duration_minutes
FROM Session_Record s
JOIN Booking b ON s.booking_id = b.booking_id
JOIN User u ON b.student_user_id = u.user_id
WHERE s.session_status = 'Completed';

-- Q5: Display all online availability slots
SELECT 
    slot_id,
    course_id,
    slot_date,
    start_time,
    end_time,
    meeting_link,
    slot_status
FROM Availability_Slot
WHERE mode = 'Online';

-- Q6: Display all bookings ordered from newest to oldest
SELECT
    booking_id,
    student_user_id,
    course_id,
    booking_status,
    booking_timestamp
FROM Booking
ORDER BY booking_timestamp DESC;

-- Q7: Display feedback along with student names and ratings
SELECT
    f.feedback_id,
    u.first_name AS student_first_name,
    u.last_name AS student_last_name,
    f.rating,
    f.comments,
    f.submitted_at
FROM Feedback f
JOIN User u ON f.student_user_id = u.user_id;

-- Q8: Display all courses along with their department names
SELECT
    c.course_id,
    c.course_code,
    c.course_title,
    d.department_name
FROM Course c
JOIN Department d ON c.department_id = d.department_id
ORDER BY c.course_code;

-- Q9: Count total bookings for each course
SELECT
    c.course_code,
    c.course_title,
    COUNT(b.booking_id) AS total_bookings
FROM Course c
LEFT JOIN Booking b ON c.course_id = b.course_id
GROUP BY c.course_id, c.course_code, c.course_title
ORDER BY total_bookings DESC;

-- Q10: Count sessions by session status
SELECT
    session_status,
    COUNT(session_id) AS total_sessions
FROM Session_Record
GROUP BY session_status;

-- Q11: Show only courses that have more than one booking
SELECT
    c.course_code,
    c.course_title,
    COUNT(b.booking_id) AS total_bookings
FROM Course c
JOIN Booking b ON c.course_id = b.course_id
GROUP BY c.course_id, c.course_code, c.course_title
HAVING COUNT(b.booking_id) > 1
ORDER BY total_bookings DESC;

-- Q12: Find students who made more than one booking
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    COUNT(b.booking_id) AS total_bookings
FROM User u
JOIN Booking b ON u.user_id = b.student_user_id
GROUP BY u.user_id, u.first_name, u.last_name
HAVING COUNT(b.booking_id) > 1;

-- Q13: Find courses whose booking count is above the average booking count across courses
SELECT
    c.course_code,
    c.course_title,
    COUNT(b.booking_id) AS total_bookings
FROM Course c
JOIN Booking b ON c.course_id = b.course_id
GROUP BY c.course_id, c.course_code, c.course_title
HAVING COUNT(b.booking_id) > (
    SELECT AVG(course_booking_count)
    FROM (
        SELECT COUNT(*) AS course_booking_count
        FROM Booking
        GROUP BY course_id
    ) AS booking_counts
);

-- Q14: Display completed sessions with provider names and student names
SELECT
    s.session_id,
    stu.first_name AS student_first_name,
    stu.last_name AS student_last_name,
    prov.first_name AS provider_first_name,
    prov.last_name AS provider_last_name,
    c.course_code,
    s.session_status,
    s.attendance_status
FROM Session_Record s
JOIN Booking b ON s.booking_id = b.booking_id
JOIN Availability_Slot a ON b.slot_id = a.slot_id
JOIN User stu ON b.student_user_id = stu.user_id
JOIN User prov ON a.provider_user_id = prov.user_id
JOIN Course c ON b.course_id = c.course_id
WHERE s.session_status = 'Completed';